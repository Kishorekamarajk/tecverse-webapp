package com.tecverse.app.service.impl;

import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.FloatBuffer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import java.util.UUID;

import javax.imageio.ImageIO;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtException;
import ai.onnxruntime.OrtSession;
import jakarta.annotation.PreDestroy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class LocalBackgroundRemovalService {

    private static final int MODEL_SIZE = 320;
    private static final int BACKGROUND_RGB = 0x063264;
    private static final double[] MEAN = {0.485, 0.456, 0.406};
    private static final double[] STANDARD_DEVIATION = {0.229, 0.224, 0.225};
    private static final String MODEL_URL =
            "https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2netp.onnx";
    private static final String MODEL_MD5 = "8e83ca70e441ab06c318d82300c84806";

    private final Path modelPath;
    private final OrtEnvironment environment = OrtEnvironment.getEnvironment();
    private volatile OrtSession session;

    public LocalBackgroundRemovalService(
            @Value("${tecverse.images.background-model-path:${UPLOADS_DIR:C:/tecverse/uploads}/models/u2netp.onnx}")
            String modelPath) {
        this.modelPath = Path.of(modelPath).toAbsolutePath().normalize();
    }

    public byte[] removeBackgroundAndApplyBrandColor(byte[] imageBytes) {
        BufferedImage original = readImage(imageBytes);
        float[] input = modelInput(original);
        try {
            OrtSession modelSession = getSession();
            try (OnnxTensor inputTensor = OnnxTensor.createTensor(
                         environment,
                         FloatBuffer.wrap(input),
                         new long[]{1, 3, MODEL_SIZE, MODEL_SIZE});
                 OrtSession.Result result = modelSession.run(
                         Map.of(modelSession.getInputNames().iterator().next(), inputTensor))) {
                float[][][][] prediction = (float[][][][]) result.get(0).getValue();
                BufferedImage mask = createMask(prediction[0][0], original.getWidth(), original.getHeight());
                return composite(original, mask);
            }
        } catch (OrtException ex) {
            throw new IllegalStateException("Local image background removal failed.", ex);
        }
    }

    private synchronized OrtSession getSession() throws OrtException {
        if (session == null) {
            ensureModelAvailable();
            session = environment.createSession(modelPath.toString(), new OrtSession.SessionOptions());
        }
        return session;
    }

    @PreDestroy
    public synchronized void closeSession() {
        if (session != null) {
            try {
                session.close();
                session = null;
            } catch (OrtException ex) {
                throw new IllegalStateException("Unable to close local image background-removal model.", ex);
            }
        }
    }

    private void ensureModelAvailable() {
        if (Files.isRegularFile(modelPath) && hasExpectedChecksum(modelPath)) {
            return;
        }
        Path temporaryModel = modelPath.resolveSibling(modelPath.getFileName() + "." + UUID.randomUUID() + ".tmp");
        try {
            Path parent = modelPath.getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }
            var connection = java.net.URI.create(MODEL_URL).toURL().openConnection();
            connection.setConnectTimeout(15_000);
            connection.setReadTimeout(120_000);
            try (var input = connection.getInputStream()) {
                Files.copy(input, temporaryModel, StandardCopyOption.REPLACE_EXISTING);
            }
            if (!hasExpectedChecksum(temporaryModel)) {
                throw new IllegalStateException("Downloaded local background-removal model failed checksum validation.");
            }
            try {
                Files.move(temporaryModel, modelPath, StandardCopyOption.REPLACE_EXISTING,
                        StandardCopyOption.ATOMIC_MOVE);
            } catch (java.nio.file.AtomicMoveNotSupportedException ex) {
                Files.move(temporaryModel, modelPath, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException ex) {
            throw new IllegalStateException(
                    "Unable to download the local background-removal model. Check server internet access and model folder permissions.",
                    ex);
        } finally {
            try {
                Files.deleteIfExists(temporaryModel);
            } catch (IOException ex) {
                throw new IllegalStateException("Unable to remove the temporary background-removal model file.", ex);
            }
        }
    }

    private static boolean hasExpectedChecksum(Path path) {
        try (var input = Files.newInputStream(path)) {
            MessageDigest digest = MessageDigest.getInstance("MD5");
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) {
                digest.update(buffer, 0, read);
            }
            return MODEL_MD5.equals(java.util.HexFormat.of().formatHex(digest.digest()));
        } catch (IOException ex) {
            return false;
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("MD5 is unavailable to validate the local image model.", ex);
        }
    }

    private static BufferedImage readImage(byte[] imageBytes) {
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (image == null) {
                throw new IllegalArgumentException("The uploaded image format cannot be processed for background removal.");
            }
            return image;
        } catch (IOException ex) {
            throw new IllegalArgumentException("Unable to read the uploaded image for background removal.", ex);
        }
    }

    private static float[] modelInput(BufferedImage source) {
        BufferedImage resized = new BufferedImage(MODEL_SIZE, MODEL_SIZE, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = resized.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.drawImage(source, 0, 0, MODEL_SIZE, MODEL_SIZE, null);
        } finally {
            graphics.dispose();
        }

        int maximumChannel = 0;
        for (int y = 0; y < MODEL_SIZE; y++) {
            for (int x = 0; x < MODEL_SIZE; x++) {
                int rgb = resized.getRGB(x, y);
                maximumChannel = Math.max(maximumChannel, rgb & 0xff);
                maximumChannel = Math.max(maximumChannel, (rgb >>> 8) & 0xff);
                maximumChannel = Math.max(maximumChannel, (rgb >>> 16) & 0xff);
            }
        }
        double divisor = Math.max(maximumChannel, 1.0e-6);
        float[] values = new float[3 * MODEL_SIZE * MODEL_SIZE];
        for (int y = 0; y < MODEL_SIZE; y++) {
            for (int x = 0; x < MODEL_SIZE; x++) {
                int rgb = resized.getRGB(x, y);
                int pixel = y * MODEL_SIZE + x;
                values[pixel] = normalize((rgb >>> 16) & 0xff, divisor, 0);
                values[MODEL_SIZE * MODEL_SIZE + pixel] = normalize((rgb >>> 8) & 0xff, divisor, 1);
                values[2 * MODEL_SIZE * MODEL_SIZE + pixel] = normalize(rgb & 0xff, divisor, 2);
            }
        }
        return values;
    }

    private static float normalize(int channel, double divisor, int index) {
        return (float) ((channel / divisor - MEAN[index]) / STANDARD_DEVIATION[index]);
    }

    private static BufferedImage createMask(float[][] prediction, int width, int height) {
        float minimum = Float.POSITIVE_INFINITY;
        float maximum = Float.NEGATIVE_INFINITY;
        for (float[] row : prediction) {
            for (float value : row) {
                if (Float.isFinite(value)) {
                    minimum = Math.min(minimum, value);
                    maximum = Math.max(maximum, value);
                }
            }
        }
        if (!Float.isFinite(minimum) || !Float.isFinite(maximum) || maximum <= minimum) {
            throw new IllegalStateException("Local image model returned an invalid foreground mask.");
        }

        BufferedImage modelMask = new BufferedImage(MODEL_SIZE, MODEL_SIZE, BufferedImage.TYPE_BYTE_GRAY);
        for (int y = 0; y < MODEL_SIZE; y++) {
            for (int x = 0; x < MODEL_SIZE; x++) {
                float value = prediction[y][x];
                int alpha = Float.isFinite(value)
                        ? Math.max(0, Math.min(255, Math.round((value - minimum) * 255 / (maximum - minimum))))
                        : 0;
                modelMask.getRaster().setSample(x, y, 0, alpha);
            }
        }

        BufferedImage resized = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_GRAY);
        Graphics2D graphics = resized.createGraphics();
        try {
            graphics.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
            graphics.drawImage(modelMask, 0, 0, width, height, null);
        } finally {
            graphics.dispose();
        }
        return resized;
    }

    static byte[] composite(BufferedImage foreground, BufferedImage mask) {
        BufferedImage output = new BufferedImage(foreground.getWidth(), foreground.getHeight(), BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < foreground.getHeight(); y++) {
            for (int x = 0; x < foreground.getWidth(); x++) {
                int source = foreground.getRGB(x, y);
                int alpha = mask.getRaster().getSample(x, y, 0);
                int red = compositeChannel((source >>> 16) & 0xff, (BACKGROUND_RGB >>> 16) & 0xff, alpha);
                int green = compositeChannel((source >>> 8) & 0xff, (BACKGROUND_RGB >>> 8) & 0xff, alpha);
                int blue = compositeChannel(source & 0xff, BACKGROUND_RGB & 0xff, alpha);
                output.setRGB(x, y, (red << 16) | (green << 8) | blue);
            }
        }
        try {
            ByteArrayOutputStream result = new ByteArrayOutputStream();
            if (!ImageIO.write(output, "png", result)) {
                throw new IllegalStateException("Unable to encode processed image as PNG.");
            }
            return result.toByteArray();
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to encode processed image.", ex);
        }
    }

    private static int compositeChannel(int foreground, int background, int alpha) {
        return (foreground * alpha + background * (255 - alpha) + 127) / 255;
    }
}
