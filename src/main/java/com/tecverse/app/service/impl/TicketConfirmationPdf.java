package com.tecverse.app.service.impl;

import com.tecverse.app.entity.TicketRegistration;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;

/** Builds the personalized, printer-friendly ticket confirmation attached to registration mail. */
final class TicketConfirmationPdf {
    private static final int PAGE_WIDTH = 595;
    private static final int PAGE_HEIGHT = 842;
    private final StringBuilder content = new StringBuilder();

    private TicketConfirmationPdf() {}

    static byte[] create(TicketRegistration registration) {
        TicketConfirmationPdf pdf = new TicketConfirmationPdf();
        pdf.draw(registration);
        return pdf.build();
    }

    private void draw(TicketRegistration registration) {
        // Two inset borders frame the confirmation while keeping it clean when printed.
        rect(22, 22, 551, 798, "0.06 0.16 0.31", 2.4f, false);
        rect(30, 30, 535, 782, "0.22 0.63 0.46", 0.9f, false);

        rect(48, 710, 499, 82, "0.04 0.13 0.27", 0, true);
        text(68, 766, "TEC-VERSE 2026", 12, true, "0.98 0.67 0.16");
        text(68, 739, "REGISTRATION CONFIRMATION", 20, true, "1 1 1");
        text(68, 721, "VISITOR PASS  |  CHENNAI TRADE CENTRE", 9, false, "0.84 0.90 0.97");

        text(50, 686, "Your registration has been confirmed", 14, true, "0.04 0.13 0.27");
        text(50, 668, "Please present this confirmation and your UIN at the venue.", 9, false, "0.30 0.36 0.43");

        text(50, 638, "TICKET DETAILS", 9, true, "0.04 0.13 0.27");
        detailRow(50, 626, "UIN / reference number", value(registration.getReferenceNumber()));
        detailRow(50, 596, "Attendee name", value(registration.getOfficialName()));
        detailRow(50, 566, "Event date(s)", eventDates(registration.getAttendanceDays()));
        detailRow(50, 536, "Venue", "Chennai Trade Centre, Chennai");

        text(50, 469, "VENUE ENTRY GUIDELINES", 10, true, "0.04 0.13 0.27");
        line(50, 460, 545, 460, "0.85 0.89 0.93", 0.8f);
        List<String> guidance = List.of(
                "Install the Tec-verse app from Google Play before you arrive.",
                "Sign in with the Gmail address and password used for your Tec-verse",
                "registration.",
                "Your registration details, QR scanner and venue information are in the app.",
                "At the entrance, use the app's QR scanner to verify your registration.",
                "Your pass is valid for the event date(s) listed above. Keep your UIN handy."
        );
        int y = 438;
        for (int i = 0; i < guidance.size(); i++) {
            // The sign-in instruction is intentionally wrapped across two lines.
            boolean continuation = i == 2;
            text(continuation ? 68 : 55, y, continuation ? guidance.get(i) : "- " + guidance.get(i), 9, false,
                    continuation ? "0.27 0.33 0.40" : "0.18 0.25 0.33");
            y -= continuation ? 15 : 25;
        }

        rect(50, 214, 495, 42, "0.92 0.97 0.94", 0, true);
        text(62, 238, "AT THE ENTRANCE", 8, true, "0.05 0.38 0.26");
        text(62, 222, "Open the Tec-verse app and present your registration QR code.", 8, false, "0.18 0.30 0.25");

        line(50, 190, 545, 190, "0.85 0.89 0.93", 0.8f);
        text(50, 170, "EVENT TIMELINE & VISITOR GUIDANCE", 9, true, "0.04 0.13 0.27");
        text(50, 153, "The event timeline and visitor guide are attached to your confirmation email.", 8, false, "0.30 0.36 0.43");
        text(50, 76, "Tec-verse 2026  |  Please follow all instructions from venue staff.", 8, false, "0.35 0.41 0.48");
    }

    private void detailRow(float x, float y, String label, String value) {
        rect(x, y - 17, 495, 27, "0.95 0.97 0.99", 0, true);
        text(x + 10, y - 1, label, 8, true, "0.34 0.41 0.49");
        text(x + 182, y - 1, value, 9, true, "0.04 0.13 0.27");
    }

    private static String eventDates(String attendance) {
        if (attendance == null || attendance.isBlank()) return "26 & 27 November 2026";
        String days = attendance.toUpperCase();
        if (days.contains("DAY_1") && !days.contains("DAY_2")) return "26 November 2026";
        if (days.contains("DAY_2") && !days.contains("DAY_1")) return "27 November 2026";
        return "26 & 27 November 2026";
    }

    private static String value(String value) {
        return value == null || value.isBlank() ? "-" : value;
    }

    private void rect(float x, float y, float width, float height, String color, float lineWidth, boolean fill) {
        content.append(color).append(fill ? " rg\n" : " RG\n");
        if (lineWidth > 0) content.append(lineWidth).append(" w\n");
        content.append(x).append(' ').append(y).append(' ').append(width).append(' ').append(height)
                .append(" re ").append(fill ? "f" : "S").append('\n');
    }

    private void line(float x1, float y1, float x2, float y2, String color, float width) {
        content.append(color).append(" RG\n").append(width).append(" w\n")
                .append(x1).append(' ').append(y1).append(" m ").append(x2).append(' ').append(y2).append(" l S\n");
    }

    private void text(float x, float y, String value, int size, boolean bold, String color) {
        content.append(color).append(" rg\nBT /F").append(bold ? 'B' : 'R').append(' ').append(size)
                .append(" Tf 1 0 0 1 ").append(x).append(' ').append(y).append(" Tm (")
                .append(pdfString(value)).append(") Tj ET\n");
    }

    private static String pdfString(String value) {
        String ascii = Normalizer.normalize(value, Normalizer.Form.NFKD)
                .replaceAll("\\p{M}+", "").replaceAll("[^\\x20-\\x7E]", "?");
        return ascii.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)");
    }

    private byte[] build() {
        byte[] stream = content.toString().getBytes(StandardCharsets.US_ASCII);
        List<byte[]> objects = new ArrayList<>();
        objects.add(ascii("<< /Type /Catalog /Pages 2 0 R >>"));
        objects.add(ascii("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"));
        objects.add(ascii("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 " + PAGE_WIDTH + " " + PAGE_HEIGHT
                + "] /Resources << /Font << /FR 4 0 R /FB 5 0 R >> >> /Contents 6 0 R >>"));
        objects.add(ascii("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"));
        objects.add(ascii("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>"));
        ByteArrayOutputStream streamObject = new ByteArrayOutputStream();
        streamObject.writeBytes(ascii("<< /Length " + stream.length + " >>\nstream\n"));
        streamObject.writeBytes(stream);
        streamObject.writeBytes(ascii("\nendstream"));
        objects.add(streamObject.toByteArray());

        ByteArrayOutputStream pdf = new ByteArrayOutputStream();
        pdf.writeBytes(ascii("%PDF-1.4\n% Tec-verse confirmation\n"));
        List<Integer> offsets = new ArrayList<>();
        for (int i = 0; i < objects.size(); i++) {
            offsets.add(pdf.size());
            pdf.writeBytes(ascii((i + 1) + " 0 obj\n"));
            pdf.writeBytes(objects.get(i));
            pdf.writeBytes(ascii("\nendobj\n"));
        }
        int xrefOffset = pdf.size();
        pdf.writeBytes(ascii("xref\n0 " + (objects.size() + 1) + "\n0000000000 65535 f \n"));
        for (int offset : offsets) pdf.writeBytes(ascii(String.format("%010d 00000 n \n", offset)));
        pdf.writeBytes(ascii("trailer\n<< /Size " + (objects.size() + 1) + " /Root 1 0 R >>\nstartxref\n"
                + xrefOffset + "\n%%EOF"));
        return pdf.toByteArray();
    }

    private static byte[] ascii(String value) {
        return value.getBytes(StandardCharsets.US_ASCII);
    }
}
