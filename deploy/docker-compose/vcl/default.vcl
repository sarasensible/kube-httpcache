  vcl 4.1;

  import directors;
  import std;


  probe frontend {
    .url = "/api/v1";
  }

  backend be-sample-engine {
      .host = "sampleengine";
      .port = "80";
  }

  backend varnish0 {
      .host = "varnish0";
      .port = "8080";
      .probe = frontend;
  }

  backend varnish1 {
      .host = "varnish1";
      .port = "8080";
      .probe = frontend;
  }


  sub vcl_init {

    new fallback = directors.fallback(true);
    fallback.add_backend(varnish0);
    fallback.add_backend(varnish1);

    new lb = directors.round_robin();
    lb.add_backend(be-sample-engine);

  }

  sub vcl_recv {


    set req.backend_hint = fallback.backend().resolve();

    std.log(req.backend_hint);

    set req.http.x-shard = req.backend_hint;

    if (req.http.x-shard == server.identity) {
      set req.backend_hint = lb.backend();
    } else {
      return(pass);
    }

    if (req.method == "PURGE") {
        if (! req.http.x-purge-control == std.getenv("PURGE_KEY")) {
          return(synth(405,"Not allowed."));
        }
        return (purge);
    }

    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }


    set req.http.url = regsub(
      req.url,
        "^lat=.*",
        "^latitude=.*"
    );

    set req.http.url = regsub(
      req.url,
        "^lon=.*",
        "^longitude=.*"
    );

    return(hash);
  }

  sub vcl_backend_response {
    set beresp.ttl = 1s;
    set beresp.grace = 0s;

    if (bereq.url ~ "forecast/") {
      set beresp.ttl = 15m;
    }

    if (bereq.url ~ "observations/") {
      set beresp.ttl = 10m;
    }

    if (bereq.url ~ "ensemble-forecast/") {
      set beresp.ttl = 15m;
    }

    if (bereq.url ~ "(analysis|climatology|downscaled|activity)/") {
      set beresp.ttl = 70h;
      set beresp.grace = 2h;
    }

    if ( beresp.status >= 400 && beresp.status < 500 ) {
      set beresp.ttl = 30s;
      set beresp.uncacheable = true;
    }

    if ( beresp.status >= 500 ) {
      if (bereq.is_bgfetch)
      {
          return (abandon);
      }
      set beresp.uncacheable = true;
    }

    # Allow built-in vcl to kick in by omitting return statement
  }

  sub vcl_deliver {
    if (obj.hits > 0) { # Add debug header to see if it's a HIT/MISS and the number of hits, disable when not needed
      set resp.http.X-Cache = "HIT";
    } else {
      set resp.http.X-Cache = "MISS";
    }
    set resp.http.x-shard = server.identity;
  }


  sub vcl_synth {
      set resp.http.Content-Type = "text/json";
      set resp.http.Retry-After = "5";
      synthetic( "{'message': '" +
                  resp.status + " " + resp.reason +
                  "'}"
      );
      return (deliver);
  }
