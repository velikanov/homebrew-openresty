require 'formula'

class NgxOpenresty < Formula
  homepage 'http://openresty.org/'

  stable do
    url 'http://openresty.org/download/ngx_openresty-1.7.4.1.tar.gz'
    sha1 'a19f95f71e9f98cc8a1f9138737c60f97e50e43c'
  end

  devel do
    url 'http://openresty.org/download/ngx_openresty-1.7.4.1rc2.tar.gz'
    sha1 'ac87a3c40e1b459a9564ddd116cf6defb8cd25aa'
  end

  resource "ip2location-nginx-module" do
    url "https://github.com/velikanov/ip2location-nginx/archive/v7.0.0.0.tar.gz"
    sha1 "6f0532737f009de34bedfe0d355626b502586c3d"
  end

  depends_on 'pcre'
  depends_on 'postgresql' => :optional
  depends_on 'geoip' => :optional
  depends_on 'velikanov/ip2location' => :optional

  # openresty options
  option 'without-luajit', "Compile *without* support for the Lua Just-In-Time Compiler"
  option 'with-postgresql', "Compile with support for direct communication with PostgreSQL database servers"
  option 'with-iconv', "Compile with support for converting character encodings"

  option 'with-debug', "Compile with support for debug logging but without proper gdb debugging symbols"

  # nginx options
  option 'with-webdav', "Compile with ngx_http_dav_module"
  option 'with-gunzip', "Compile with ngx_http_gunzip_module"
  option 'with-geoip', "Compile with ngx_http_geoip_module"
  option 'with-ip2location', "Compile with ngx_http_ip2location_module"
  option 'with-realip', "Complile with ngx_http_realip_module"

  skip_clean 'nginx/logs'

  def install
    args = ["--prefix=#{prefix}",
      "--with-http_ssl_module",
      "--with-pcre",
      "--with-pcre-jit",
      "--sbin-path=#{bin}/openresty",
      "--conf-path=#{etc}/openresty/nginx.conf",
      "--pid-path=#{var}/run/openresty.pid",
      "--lock-path=#{var}/openresty/nginx.lock"
    ]

    args << "--with-http_dav_module" if build.with? 'webdav'
    args << "--with-http_gunzip_module" if build.with? 'gunzip'
    args << "--with-http_geoip_module" if build.with? 'geoip'
    args << "--with-http_realip_module" if build.with? 'realip'

    # Debugging mode, unfortunately without debugging symbols
    if build.with? 'debug'
      args << '--with-debug'
      args << '--with-dtrace-probes'
      args << '--with-no-pool-patch'
      
      # this allows setting of `debug.sethook` in luajit
      unless build.without? 'luajit'
        args << '--with-luajit-xcflags=-DLUAJIT_ENABLE_CHECKHOOK'
      end
      
      opoo "Openresty will be built --with-debug option, but without debugging symbols. For debugging symbols you have to compile it by hand."
    end

    if build.with? 'velikanov/ip2location'
      resource("ip2location-nginx-module").stage {
        (buildpath/"ngx_ip2location-7.0.0").install Dir["./*"]
      }

      args << "--add-module=ngx_ip2location-7.0.0"
    end

    # OpenResty options
    args << "--with-lua51" if build.without? 'luajit'

    args << "--with-http_postgres_module" if build.with? 'postgres'
    args << "--with-http_iconv_module" if build.with? 'iconv'

    system "./configure", *args

    system "make"
    system "make install"
  end
end
