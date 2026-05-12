vcl 4.1;

backend default {
    .host = "nginx";
    .port = "8080";
    .connect_timeout = 600s;
    .first_byte_timeout = 600s;
    .between_bytes_timeout = 600s;
}

sub vcl_recv {
    # Pass admin, account, checkout — never cache
    if (req.url ~ "^/myadminpanel" ||
        req.url ~ "^/customer" ||
        req.url ~ "^/checkout" ||
        req.url ~ "^/wishlist") {
        return (pass);
    }

    # Pass non-GET/HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Strip all cookies except the ones Magento needs for personalisation
    if (req.http.Cookie) {
        set req.http.Cookie = regsuball(req.http.Cookie,
            "(^|;\s*)(PHPSESSID|frontend|mage-cache-sessid|mage-cache-storage|mage-cache-storage-section-invalidation|mage-messages|mage-translation-file-version|mage-translation-storage|private_content_version|form_key|recently_viewed_product|recently_compared_product|product_data_storage|customer_data_section_load_error|section_data_ids)[^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

        # If no cookies remain after stripping — hash (cache it)
        if (req.http.Cookie ~ "^\s*$") {
            unset req.http.Cookie;
            return (hash);
        }
    }

    return (hash);
}

sub vcl_backend_response {
    # Strip Set-Cookie on cacheable responses so Varnish stores them
    if (bereq.url !~ "^/myadminpanel" &&
        bereq.url !~ "^/customer" &&
        bereq.url !~ "^/checkout") {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 1h;
    }

    # Static assets — cache longer
    if (bereq.url ~ "\.(css|js|png|jpg|jpeg|gif|ico|woff|woff2|svg|ttf|eot)$") {
        set beresp.ttl = 1d;
        unset beresp.http.Set-Cookie;
    }
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Varnish-Cache = "HIT";
    } else {
        set resp.http.X-Varnish-Cache = "MISS";
    }
}
