package com.tecverse.app.security;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.List;

import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Restores the real client address and HTTPS scheme when the app runs behind the reverse proxy.
 * <p>
 * The app is deployed as a WAR on an external Tomcat, where Spring Boot's
 * {@code server.forward-headers-strategy} has no effect. X-Forwarded-* headers are honoured only
 * when the direct peer is a trusted proxy, and the client IP is the right-most untrusted entry of
 * X-Forwarded-For, so a visitor cannot spoof their address to dodge rate limits.
 */
public final class TrustedProxyFilter extends OncePerRequestFilter {

    private final List<Cidr> trustedProxies;

    public TrustedProxyFilter(String trustedProxyList) {
        this.trustedProxies = Arrays.stream(trustedProxyList.split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).map(Cidr::parse).toList();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (!isTrusted(request.getRemoteAddr())) {
            filterChain.doFilter(request, response);
            return;
        }
        String clientIp = clientIp(request.getHeader("X-Forwarded-For"), request.getRemoteAddr());
        String proto = first(request.getHeader("X-Forwarded-Proto"));
        boolean https = proto != null ? "https".equalsIgnoreCase(proto) : request.isSecure();
        String forwardedHost = first(request.getHeader("X-Forwarded-Host"));
        String host = forwardedHost != null ? forwardedHost.replaceFirst(":\\d+$", "") : request.getServerName();
        int port = forwardedPort(request.getHeader("X-Forwarded-Port"), forwardedHost, proto != null, https,
                request.getServerPort());

        filterChain.doFilter(new HttpServletRequestWrapper(request) {
            @Override public String getRemoteAddr() { return clientIp; }
            @Override public String getRemoteHost() { return clientIp; }
            @Override public String getScheme() { return https ? "https" : "http"; }
            @Override public boolean isSecure() { return https; }
            @Override public String getServerName() { return host; }
            @Override public int getServerPort() { return port; }
            @Override public StringBuffer getRequestURL() {
                StringBuffer url = new StringBuffer(getScheme()).append("://").append(host);
                if (!(https && port == 443) && !(!https && port == 80)) url.append(':').append(port);
                return url.append(getRequestURI());
            }
        }, response);
    }

    private String clientIp(String forwardedFor, String peer) {
        if (forwardedFor == null || forwardedFor.isBlank()) return peer;
        String[] hops = forwardedFor.split(",");
        for (int i = hops.length - 1; i >= 0; i--) {
            String hop = hops[i].trim();
            if (!hop.isEmpty() && !isTrusted(hop)) return hop;
        }
        return hops[0].trim().isEmpty() ? peer : hops[0].trim();
    }

    /** Explicit X-Forwarded-Port, else a port in X-Forwarded-Host, else the scheme default once the proxy declared one. */
    private static int forwardedPort(String portHeader, String forwardedHost, boolean protoForwarded, boolean https,
                                     int serverPort) {
        String value = first(portHeader);
        if (value == null && forwardedHost != null && forwardedHost.matches(".*:\\d+$")) {
            value = forwardedHost.substring(forwardedHost.lastIndexOf(':') + 1);
        }
        if (value != null && value.matches("\\d{1,5}")) return Integer.parseInt(value);
        if (protoForwarded || forwardedHost != null) return https ? 443 : 80;
        return serverPort;
    }

    private static String first(String header) {
        if (header == null || header.isBlank()) return null;
        return header.split(",")[0].trim();
    }

    private boolean isTrusted(String address) {
        return trustedProxies.stream().anyMatch(cidr -> cidr.contains(address));
    }

    private record Cidr(byte[] network, int prefix) {
        static Cidr parse(String value) {
            String[] parts = value.split("/");
            byte[] address = toBytes(parts[0]);
            if (address == null) throw new IllegalArgumentException("Invalid trusted proxy address: " + value);
            int prefix = parts.length > 1 ? Integer.parseInt(parts[1]) : address.length * 8;
            return new Cidr(address, prefix);
        }

        boolean contains(String candidate) {
            byte[] address = toBytes(candidate);
            if (address == null || address.length != network.length) return false;
            int fullBytes = prefix / 8, remainingBits = prefix % 8;
            for (int i = 0; i < fullBytes; i++) if (address[i] != network[i]) return false;
            if (remainingBits == 0) return true;
            int mask = 0xFF << (8 - remainingBits);
            return (address[fullBytes] & mask) == (network[fullBytes] & mask);
        }

        private static byte[] toBytes(String literal) {
            // Only IP literals are accepted, so no DNS lookup can happen here.
            if (literal == null || !literal.matches("[0-9a-fA-F:.]+")) return null;
            try {
                return InetAddress.getByName(literal).getAddress();
            } catch (UnknownHostException e) {
                return null;
            }
        }
    }
}
