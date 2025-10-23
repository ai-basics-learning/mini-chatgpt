class ChatResponsesController < ApplicationController
  include ActionController::Live

  def show
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    sse = SSE.new(response.stream, event: 'message')
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    begin
      client.chat(parameters: {
          model: 'gpt-3.5-turbo',
          message: {role: 'user', content: params[:prompt]},
          stream: proc do |chunk|
            # content = chunk.dig ("choices", 0, 'delta', 'content')
            content = chunk.dig("choices", 0, "delta", "content")
            return if content.nil?
            sse.write ({message: content})
          end

      })
    ensure
      #Todo: Remove below line after adding credit
      sse.write ({message: 'Unable to reach chatgpat due to credits..'})

      sse.close
    end

  end
end
