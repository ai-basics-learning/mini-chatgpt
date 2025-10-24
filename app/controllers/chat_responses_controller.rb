class ChatResponsesController < ApplicationController
  include ActionController::Live

  def show
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    sse = SSE.new(response.stream, event: 'message')
    client = OpenAI::Client.new(access_token: ENV.fetch("GROQ_API_KEY"),
                                uri_base: "https://api.groq.com/openai/v1")

    begin
      client.chat(parameters: {model: "llama-3.1-8b-instant",
                               messages: [{role: "system", content: "You are a helpful assistant."},
                                          {role: "user", content: params[:prompt]}],
                               temperature: 0.7,
                               max_tokens: 256,
                               stream: proc do |chunk|
                                 content = chunk.dig("choices", 0, "delta", "content")
                                 return if content.nil?
                                 Rails.logger.info content
                                 sse.write ({message: content})
                               end})
    rescue Faraday::BadRequestError => e
      puts "Bad request!  Response body:\n#{e.response[:body]}" if e.respond_to?(:response)
    ensure

      sse.close
    end

  end
end
