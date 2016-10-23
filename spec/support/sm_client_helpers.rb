# frozen_string_literal: true
module SM
  module ClientHelpers
    HOST = ENV['MHV_SM_HOST']
    APP_TOKEN = 'fake-app-token'
    TOKEN = '2exSxvcXq/Q=8RXZtaeZrRAkyXTbXfQrjWMVqSza277kcExaQM/BTOE='

    SAMPLE_SESSION_RESPONSE = {
      status: 200,
      body: '',
      headers: {
        'date' => 'Tue, 10 May 2016 16:30:17 GMT',
        'server' => 'Apache/2.2.15 (Red Hat)',
        'content-length' => '0',
        'expires' => 'Tue, 10 May 2016 16:40:17 GMT',
        'token' => TOKEN,
        'x-powered-by' => 'Servlet/2.5 JSP/2.1',
        'connection' => 'close',
        'content-type' => 'text/plain; charset=UTF-8',
        'cache-control' => 'no-cache',
        'access-control-allow-origin' => '*'
      }
    }.freeze

    def setup_client
      stub_request(:get, "#{HOST}/mhv-sm-api/patient/v1/session")
        .to_return(SAMPLE_SESSION_RESPONSE)

      SM::Client.new(session: { user_id: 123 })
    end

    def authenticated_client
      SM::Client.new(session: { user_id: 123,
                                expires_at: Time.current + 60 * 60,
                                token: TOKEN })
    end
  end
end
