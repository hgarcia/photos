require 'rubygems'
require 'rack'
require 'rack/contrib'
require 'rack-rewrite'
require 'mime/types'

use Rack::ETag
module ::Rack
    class TryStatic < Static

        def initialize(app, options)
            super
            @try = ([''] + Array(options.delete(:try)) + [''])
        end

        def call(env)
            @next = 0
            while @next < @try.size && 404 == (resp = super(try_next(env)))[0] 
                @next += 1
            end
            404 == resp[0] ? @app.call : resp
        end

        private
        def try_next(env)
        	key = 'PATH_INFO'
            path_info = env[key]
            env.merge(key => path_info + @try[@next])
        end

    end
end

use Rack::TryStatic, 
    :root => "_site",                              # static files root dir
    :urls => %w[/],                                 # match all requests 
    :try => ['.html', 'index.html', '/index.html']  # try these postfixes sequentially

errorFile='_site/index.html'
run lambda { [404, {
                "Content-Type"   => "text/html",
                "Content-Length" => File.size(errorFile).to_s
            }, File.read(errorFile)] }