package com.tecverse.app.service;

import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.GradientPaint;
import java.awt.Graphics2D;
import java.awt.Polygon;
import java.awt.RenderingHints;
import java.awt.geom.Ellipse2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

@Service
public class AdminIdCardPdfService {
    private static final int WIDTH = 740;
    private static final int HEIGHT = 1040;
    private final QRCodeGeneratorService qrCodeGeneratorService;
    private final JdbcTemplate jdbcTemplate;

    public AdminIdCardPdfService(QRCodeGeneratorService qrCodeGeneratorService, JdbcTemplate jdbcTemplate) {
        this.qrCodeGeneratorService = qrCodeGeneratorService;
        this.jdbcTemplate = jdbcTemplate;
    }

    public GeneratedCard generate(String name, String designation, String organization, String category, byte[] photoBytes) throws IOException {
        String reference = nextReference(category);
        String qrValue = "TECVERSE 2026 ID CARD\nReference: " + reference + "\nCategory: " + category
                + "\nName: " + name + "\nDesignation: " + designation + "\nOrganization: " + organization;
        byte[] qrBytes = qrCodeGeneratorService.generateQRCodeImageBytes(qrValue, 360, 360);
        BufferedImage qr = ImageIO.read(new ByteArrayInputStream(qrBytes));
        BufferedImage photo = photoBytes == null ? null : ImageIO.read(new ByteArrayInputStream(photoBytes));
        if (photoBytes != null && photo == null) throw new IllegalArgumentException("The uploaded file is not a supported image.");
        BufferedImage card = drawCard(name, designation, organization, category, reference, qr, photo);
        byte[] pdf = toPdf(card);
        saveCardDetails(reference, name, designation, organization, category, photo);
        return new GeneratedCard(reference, pdf);
    }

    private void saveCardDetails(String reference, String name, String designation, String organization,
                                 String category, BufferedImage photo) throws IOException {
        Path photoPath = null;
        String storedPhotoPath = null;
        if (photo != null) {
            Path photoDirectory = Path.of("uploads", "admin-id-card-photos").toAbsolutePath();
            Files.createDirectories(photoDirectory);
            photoPath = photoDirectory.resolve(reference + ".png");
            if (!ImageIO.write(photo, "png", photoPath.toFile())) {
                throw new IOException("Could not save the ID card photo.");
            }
            storedPhotoPath = Path.of("uploads", "admin-id-card-photos", reference + ".png").toString().replace('\\', '/');
        }

        try {
            jdbcTemplate.update("""
                    INSERT INTO admin_id_cards (reference_number, category, name, designation, organization, photo_path)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """, reference, category, name, designation, organization, storedPhotoPath);
        } catch (RuntimeException exception) {
            if (photoPath != null) {
                try {
                    Files.deleteIfExists(photoPath);
                } catch (IOException cleanupException) {
                    exception.addSuppressed(cleanupException);
                }
            }
            throw exception;
        }
    }

    private String nextReference(String category) {
        String counterKey = switch (category) {
            case "SPEAKER" -> "speaker";
            case "ORGANIZER" -> "organizer";
            case "VIP" -> "vip";
            default -> throw new IllegalArgumentException("Unsupported card category.");
        };
        String prefix = switch (category) {
            case "SPEAKER" -> "TV26SP";
            case "ORGANIZER" -> "TV26OG";
            case "VIP" -> "TV26VP";
            default -> throw new IllegalArgumentException("Unsupported card category.");
        };
        Path counterFile = Path.of("uploads", "admin-id-card-counters.properties").toAbsolutePath();
        Path parent = counterFile.getParent();
        try {
            Files.createDirectories(parent);
            Path lockFile = parent.resolve("admin-id-card-counters.lock");
            try (FileChannel channel = FileChannel.open(lockFile, StandardOpenOption.CREATE, StandardOpenOption.WRITE);
                 FileLock ignored = channel.lock()) {
                Properties counters = new Properties();
                if (Files.exists(counterFile)) {
                    try (var input = Files.newInputStream(counterFile)) {
                        counters.load(input);
                    }
                }
                long current = Long.parseLong(counters.getProperty(counterKey, "0")) + 1;
                if (current > 999_999) {
                    throw new IllegalStateException("The " + category.toLowerCase(java.util.Locale.ROOT) + " ID card reference sequence is exhausted.");
                }
                counters.setProperty(counterKey, Long.toString(current));
                Path temporaryFile = Files.createTempFile(parent, "admin-id-card-counters-", ".tmp");
                try {
                    try (var output = Files.newOutputStream(temporaryFile, StandardOpenOption.TRUNCATE_EXISTING)) {
                        counters.store(output, "TECVERSE 2026 admin ID card counters");
                    }
                    try {
                        Files.move(temporaryFile, counterFile, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
                    } catch (java.nio.file.AtomicMoveNotSupportedException ignoredMove) {
                        Files.move(temporaryFile, counterFile, StandardCopyOption.REPLACE_EXISTING);
                    }
                } finally {
                    Files.deleteIfExists(temporaryFile);
                }
                return prefix + String.format(java.util.Locale.ROOT, "%06d", current);
            }
        } catch (IOException | NumberFormatException exception) {
            throw new IllegalStateException("Could not allocate an ID card reference number.", exception);
        }
    }

    private BufferedImage drawCard(String name, String designation, String organization, String category,
                                   String reference, BufferedImage qr, BufferedImage photo) throws IOException {
        BufferedImage image = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setColor(new Color(235, 244, 255));
        g.fillRect(0, 0, WIDTH, HEIGHT);
        g.setColor(Color.WHITE);
        g.fillRoundRect(26, 18, WIDTH - 52, HEIGHT - 36, 46, 46);
        g.setClip(26, 18, WIDTH - 52, HEIGHT - 36);
        g.setPaint(new GradientPaint(30, 20, new Color(0, 119, 224), WIDTH - 30, 310, new Color(4, 24, 83)));
        g.fillRect(26, 18, WIDTH - 52, 300);
        g.setColor(new Color(0, 190, 255, 125));
        g.setStroke(new BasicStroke(2));
        for (int i = 0; i < 5; i++) g.drawOval(-300 + i * 38, -150 + i * 15, 470, 470);
        for (int row = 0; row < 4; row++) {
            for (int col = 0; col < 5; col++) {
                g.fillOval(58 + col * 18, 46 + row * 18, 5, 5);
                g.fillOval(604 + col * 18, 133 + row * 18, 5, 5);
            }
        }
        g.setColor(new Color(255, 155, 32));
        g.fill(new Polygon(new int[]{610, 714, 714, 678}, new int[]{18, 18, 111, 53}, 4));
        g.setColor(new Color(0, 181, 246, 180));
        g.setStroke(new BasicStroke(4));
        g.drawArc(524, 45, 245, 245, 205, 120);

        BufferedImage logo;
        try (var logoStream = new ClassPathResource("static/images/tecverselogo.png").getInputStream()) {
            logo = ImageIO.read(logoStream);
        }
        g.setColor(Color.WHITE);
        g.fillOval(WIDTH / 2 - 66, 42, 132, 132);
        drawContained(g, logo, WIDTH / 2 - 57, 51, 114, 114);
        g.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 42));
        String brand = "Tec-Verse ";
        int brandWidth = g.getFontMetrics().stringWidth(brand + "2026");
        int brandX = (WIDTH - brandWidth) / 2;
        g.drawString(brand, brandX, 218);
        g.setColor(new Color(0, 211, 255));
        g.drawString("2026", brandX + g.getFontMetrics().stringWidth(brand), 218);
        g.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 21));
        g.setColor(new Color(230, 237, 255));
        centered(g, "Driving Progress Through Innovation", 260);
        g.setColor(new Color(255, 155, 32));
        g.fillRoundRect(WIDTH / 2 - 22, 279, 43, 5, 5, 5);
        g.setColor(new Color(0, 187, 255));
        g.fillRoundRect(WIDTH / 2 + 25, 279, 39, 5, 5, 5);

        g.setColor(new Color(248, 252, 255));
        g.fillRect(26, 300, WIDTH - 52, 550);
        g.setColor(new Color(214, 236, 255));
        for (int row = 0; row < 4; row++) for (int col = 0; col < 5; col++) {
            g.fillOval(55 + col * 14, 333 + row * 14, 4, 4);
            g.fillOval(624 + col * 14, 716 + row * 14, 4, 4);
        }

        if (photo != null) {
            g.setColor(new Color(215, 239, 255));
            g.fillOval(62, 348, 260, 260);
            g.setColor(Color.WHITE);
            g.fillOval(70, 356, 244, 244);
            g.setColor(new Color(69, 176, 255));
            g.setStroke(new BasicStroke(3));
            g.drawOval(70, 356, 244, 244);
            ShapeClip.drawCircle(g, photo, 82, 368, 220);
        }
        int qrSize = photo == null ? 286 : 246;
        int qrX = photo == null ? (WIDTH - qrSize) / 2 : 400;
        int qrY = photo == null ? 368 : 374;
        int frameSize = qrSize + 30;
        int frameX = qrX - 15;
        int frameY = qrY - 15;
        g.setColor(Color.WHITE);
        g.fillRoundRect(frameX, frameY, frameSize, frameSize, 24, 24);
        g.setColor(new Color(183, 222, 255));
        g.setStroke(new BasicStroke(2));
        g.drawRoundRect(frameX, frameY, frameSize, frameSize, 24, 24);
        g.drawImage(qr, qrX, qrY, qrSize, qrSize, null);
        drawQrCorners(g, frameX, frameY, frameSize);

        int nameY = photo == null ? 730 : 682;
        g.setColor(new Color(10, 34, 82));
        g.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 48));
        drawWrappedCentered(g, name.toUpperCase(java.util.Locale.ROOT), nameY, 620, 55, 2);
        int detailsTop = nameY + 31;
        g.setColor(new Color(255, 157, 28));
        g.fillRoundRect(WIDTH / 2 - 54, detailsTop, 43, 6, 6, 6);
        g.setColor(new Color(105, 203, 255));
        g.fillRoundRect(WIDTH / 2 - 5, detailsTop, 94, 6, 6, 6);
        g.setColor(new Color(73, 92, 135));
        g.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 27));
        drawWrappedCentered(g, designation, detailsTop + 52, 640, 34, 2);
        g.setColor(new Color(11, 35, 82));
        g.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 24));
        drawWrappedCentered(g, organization, detailsTop + 103, 640, 31, 2);

        int bandY = 828;
        g.setPaint(new GradientPaint(26, bandY, new Color(18, 48, 188), WIDTH - 26, bandY + 95, new Color(57, 40, 198)));
        g.fillRoundRect(26, bandY, WIDTH - 52, 104, 36, 36);
        g.setColor(new Color(0, 197, 255, 150));
        g.setStroke(new BasicStroke(3));
        g.drawArc(28, bandY - 50, 270, 170, 190, 125);
        g.setColor(new Color(255, 147, 37));
        g.drawArc(WIDTH - 290, bandY - 52, 270, 170, 220, 120);
        g.setColor(Color.WHITE);
        g.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 34));
        centered(g, categoryLabel(category), bandY + 65);

        g.setColor(new Color(241, 249, 255));
        g.fillRect(26, 932, WIDTH - 52, 90);
        g.setColor(new Color(99, 119, 157));
        g.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 18));
        centered(g, "REFERENCE", 960);
        int refWidth = Math.max(270, g.getFontMetrics().stringWidth(reference) + 50);
        g.setColor(new Color(204, 231, 255));
        g.fillRoundRect((WIDTH - refWidth) / 2, 972, refWidth, 46, 23, 23);
        g.setColor(new Color(99, 187, 255));
        g.setStroke(new BasicStroke(2));
        g.drawRoundRect((WIDTH - refWidth) / 2, 972, refWidth, 46, 23, 23);
        g.setColor(new Color(10, 34, 82));
        g.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 24));
        centered(g, reference, 1003);
        g.setClip(null);
        g.setColor(new Color(199, 225, 250));
        g.setStroke(new BasicStroke(3));
        g.drawRoundRect(26, 18, WIDTH - 52, HEIGHT - 36, 46, 46);
        g.dispose();
        return image;
    }

    private static void drawQrCorners(Graphics2D g, int x, int y, int size) {
        g.setColor(new Color(0, 138, 255));
        g.setStroke(new BasicStroke(7, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        int corner = 29;
        g.drawLine(x, y + corner, x, y); g.drawLine(x, y, x + corner, y);
        g.drawLine(x + size - corner, y, x + size, y); g.drawLine(x + size, y, x + size, y + corner);
        g.drawLine(x, y + size - corner, x, y + size); g.drawLine(x, y + size, x + corner, y + size);
        g.drawLine(x + size - corner, y + size, x + size, y + size); g.drawLine(x + size, y + size - corner, x + size, y + size);
    }

    private static void drawContained(Graphics2D g, BufferedImage source, int x, int y, int width, int height) {
        double scale = Math.min((double) width / source.getWidth(), (double) height / source.getHeight());
        int drawWidth = (int) (source.getWidth() * scale);
        int drawHeight = (int) (source.getHeight() * scale);
        g.drawImage(source, x + (width - drawWidth) / 2, y + (height - drawHeight) / 2, drawWidth, drawHeight, null);
    }

    private static void centered(Graphics2D g, String text, int baseline) {
        g.drawString(text, (WIDTH - g.getFontMetrics().stringWidth(text)) / 2, baseline);
    }

    private static void drawWrappedCentered(Graphics2D g, String text, int centerY, int maxWidth, int lineHeight, int maxLines) {
        List<String> lines = wrap(text, g, maxWidth, maxLines);
        int startY = centerY - (lines.size() - 1) * lineHeight / 2;
        for (int i = 0; i < lines.size(); i++) centered(g, lines.get(i), startY + i * lineHeight);
    }

    private static List<String> wrap(String text, Graphics2D g, int maxWidth, int maxLines) {
        List<String> lines = new ArrayList<>();
        StringBuilder line = new StringBuilder();
        for (String word : text.trim().split("\\s+")) {
            String candidate = line.isEmpty() ? word : line + " " + word;
            if (g.getFontMetrics().stringWidth(candidate) > maxWidth && !line.isEmpty()) {
                lines.add(line.toString());
                line.setLength(0);
                line.append(word);
            } else {
                line.setLength(0);
                line.append(candidate);
            }
        }
        if (!line.isEmpty()) lines.add(line.toString());
        if (lines.size() > maxLines) {
            lines = new ArrayList<>(lines.subList(0, maxLines));
            String last = lines.get(maxLines - 1);
            while (g.getFontMetrics().stringWidth(last + "…") > maxWidth && !last.isEmpty()) last = last.substring(0, last.length() - 1);
            lines.set(maxLines - 1, last + "…");
        }
        return lines;
    }

    private static String categoryLabel(String category) {
        return switch (category) {
            case "VIP" -> "VIP / SPECIAL INVITEE";
            case "ORGANIZER" -> "ORGANIZER";
            default -> "SPEAKER";
        };
    }

    private static byte[] toPdf(BufferedImage image) throws IOException {
        ByteArrayOutputStream jpeg = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", jpeg);
        byte[] imageBytes = jpeg.toByteArray();
        byte[] content = "q 370 0 0 520 0 0 cm /Card Do Q".getBytes(StandardCharsets.US_ASCII);
        List<byte[]> objects = new ArrayList<>();
        objects.add(ascii("<< /Type /Catalog /Pages 2 0 R >>"));
        objects.add(ascii("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"));
        objects.add(ascii("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 370 520] /Resources << /XObject << /Card 4 0 R >> >> /Contents 5 0 R >>"));
        ByteArrayOutputStream imageObject = new ByteArrayOutputStream();
        imageObject.writeBytes(ascii("<< /Type /XObject /Subtype /Image /Width " + image.getWidth() + " /Height " + image.getHeight()
                + " /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length " + imageBytes.length + " >>\nstream\n"));
        imageObject.writeBytes(imageBytes);
        imageObject.writeBytes(ascii("\nendstream"));
        objects.add(imageObject.toByteArray());
        objects.add(ascii("<< /Length " + content.length + " >>\nstream\n" + new String(content, StandardCharsets.US_ASCII) + "\nendstream"));

        ByteArrayOutputStream pdf = new ByteArrayOutputStream();
        pdf.writeBytes(ascii("%PDF-1.4\n% Tec-verse ID card\n"));
        List<Integer> offsets = new ArrayList<>();
        for (int i = 0; i < objects.size(); i++) {
            offsets.add(pdf.size());
            pdf.writeBytes(ascii((i + 1) + " 0 obj\n"));
            pdf.writeBytes(objects.get(i));
            pdf.writeBytes(ascii("\nendobj\n"));
        }
        int xref = pdf.size();
        pdf.writeBytes(ascii("xref\n0 " + (objects.size() + 1) + "\n0000000000 65535 f \n"));
        for (int offset : offsets) pdf.writeBytes(ascii(String.format("%010d 00000 n \n", offset)));
        pdf.writeBytes(ascii("trailer\n<< /Size " + (objects.size() + 1) + " /Root 1 0 R >>\nstartxref\n" + xref + "\n%%EOF"));
        return pdf.toByteArray();
    }

    private static byte[] ascii(String value) {
        return value.getBytes(StandardCharsets.US_ASCII);
    }

    private static final class ShapeClip {
        private static void drawCircle(Graphics2D graphics, BufferedImage source, int x, int y, int diameter) {
            Graphics2D clipped = (Graphics2D) graphics.create();
            clipped.setClip(new Ellipse2D.Double(x, y, diameter, diameter));
            clipped.drawImage(source, x, y, diameter, diameter, null);
            clipped.dispose();
        }
    }

    public record GeneratedCard(String reference, byte[] pdf) {}
}
