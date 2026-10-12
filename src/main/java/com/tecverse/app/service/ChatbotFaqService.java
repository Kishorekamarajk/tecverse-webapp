package com.tecverse.app.service;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.tecverse.app.dto.ChatbotFaq;

import javax.xml.parsers.DocumentBuilderFactory;

@Service
public class ChatbotFaqService {

    private static final String[] WORKBOOK_LOCATIONS = {
            "classpath:/static/docs/chatbot.xlsx",
            "classpath:/static/docs/Chatbot.xlsx"
    };

    private final ResourceLoader resourceLoader;

    public ChatbotFaqService(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    public List<ChatbotFaq> getFaqs() {
        Resource workbookResource = findWorkbook();

        try (InputStream inputStream = workbookResource.getInputStream()) {
            Map<String, byte[]> entries = readZipEntries(inputStream);
            byte[] sheetXml = entries.get("xl/worksheets/sheet1.xml");
            if (sheetXml == null) {
                return List.of();
            }

            List<String> sharedStrings = readSharedStrings(entries.get("xl/sharedStrings.xml"));
            List<Map<Integer, String>> rows = readSheetRows(sheetXml, sharedStrings);
            if (rows.isEmpty()) {
                return List.of();
            }

            Map<Integer, String> header = rows.get(0);
            int categoryColumn = columnIndex(header, "category", 1);
            int questionColumn = columnIndex(header, "question", 2);
            int answerColumn = columnIndex(header, "answer", 3);

            List<ChatbotFaq> faqs = new ArrayList<>();
            for (int rowIndex = 1; rowIndex < rows.size(); rowIndex++) {
                Map<Integer, String> row = rows.get(rowIndex);
                String question = cellText(row, questionColumn);
                String answer = cellText(row, answerColumn);
                if (question.isBlank() || answer.isBlank()) {
                    continue;
                }

                faqs.add(new ChatbotFaq(cellText(row, categoryColumn), question, answer));
            }

            return faqs;
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to load chatbot questions from Excel.", ex);
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to parse chatbot questions from Excel.", ex);
        }
    }

    private Resource findWorkbook() {
        for (String location : WORKBOOK_LOCATIONS) {
            Resource resource = resourceLoader.getResource(location);
            if (resource.exists()) {
                return resource;
            }
        }
        throw new IllegalStateException("Chatbot Excel file was not found in static/docs.");
    }

    private static Map<String, byte[]> readZipEntries(InputStream inputStream) throws IOException {
        Map<String, byte[]> entries = new HashMap<>();

        try (ZipInputStream zipInputStream = new ZipInputStream(inputStream)) {
            ZipEntry entry;
            while ((entry = zipInputStream.getNextEntry()) != null) {
                if (!entry.isDirectory()) {
                    entries.put(entry.getName(), zipInputStream.readAllBytes());
                }
            }
        }

        return entries;
    }

    private static List<String> readSharedStrings(byte[] sharedStringsXml) throws Exception {
        if (sharedStringsXml == null) {
            return List.of();
        }

        Document document = parseXml(sharedStringsXml);
        NodeList items = document.getElementsByTagName("si");
        List<String> sharedStrings = new ArrayList<>();
        for (int i = 0; i < items.getLength(); i++) {
            sharedStrings.add(textFromDescendants((Element) items.item(i), "t"));
        }
        return sharedStrings;
    }

    private static List<Map<Integer, String>> readSheetRows(byte[] sheetXml, List<String> sharedStrings) throws Exception {
        Document document = parseXml(sheetXml);
        NodeList rowNodes = document.getElementsByTagName("row");
        List<Map<Integer, String>> rows = new ArrayList<>();

        for (int i = 0; i < rowNodes.getLength(); i++) {
            Element rowElement = (Element) rowNodes.item(i);
            NodeList cells = rowElement.getElementsByTagName("c");
            Map<Integer, String> row = new TreeMap<>();

            for (int j = 0; j < cells.getLength(); j++) {
                Element cell = (Element) cells.item(j);
                int columnIndex = columnIndexFromReference(cell.getAttribute("r"));
                if (columnIndex >= 0) {
                    row.put(columnIndex, cellValue(cell, sharedStrings));
                }
            }

            rows.add(row);
        }

        return rows;
    }

    private static Document parseXml(byte[] xml) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        factory.setExpandEntityReferences(false);
        return factory.newDocumentBuilder().parse(new java.io.ByteArrayInputStream(xml));
    }

    private static String cellValue(Element cell, List<String> sharedStrings) {
        String type = cell.getAttribute("t");
        if ("inlineStr".equals(type)) {
            return textFromDescendants(cell, "t").trim();
        }

        String value = textFromDescendants(cell, "v").trim();
        if ("s".equals(type) && !value.isBlank()) {
            int sharedStringIndex = Integer.parseInt(value);
            if (sharedStringIndex >= 0 && sharedStringIndex < sharedStrings.size()) {
                return sharedStrings.get(sharedStringIndex).trim();
            }
        }

        return value;
    }

    private static String textFromDescendants(Element element, String tagName) {
        NodeList nodes = element.getElementsByTagName(tagName);
        StringBuilder text = new StringBuilder();
        for (int i = 0; i < nodes.getLength(); i++) {
            text.append(nodes.item(i).getTextContent());
        }
        return text.toString();
    }

    private static int columnIndex(Map<Integer, String> header, String expectedHeader, int fallbackIndex) {
        for (Map.Entry<Integer, String> entry : header.entrySet()) {
            String value = entry.getValue()
                    .toLowerCase(Locale.ENGLISH)
                    .replaceAll("[^a-z0-9]", "");
            if (value.equals(expectedHeader)) {
                return entry.getKey();
            }
        }

        return fallbackIndex;
    }

    private static int columnIndexFromReference(String reference) {
        int columnIndex = 0;
        int letters = 0;
        for (int i = 0; i < reference.length(); i++) {
            char current = Character.toUpperCase(reference.charAt(i));
            if (current < 'A' || current > 'Z') {
                break;
            }
            columnIndex = (columnIndex * 26) + (current - 'A' + 1);
            letters++;
        }
        return letters == 0 ? -1 : columnIndex - 1;
    }

    private static String cellText(Map<Integer, String> row, int columnIndex) {
        return row.getOrDefault(columnIndex, "").trim();
    }
}
