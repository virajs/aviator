require 'test_helper'

class Aviator::Test

  describe 'aviator/core/service' do

    def config
      Environment.openstack_admin
    end
    
    def klass
      Aviator::Service
    end

    def service(default_session_data=nil)
      options = {
        provider: config[:provider],
        service:  config[:auth_service][:name]
      }
      
      options[:default_session_data] = default_session_data unless default_session_data.nil?
      
      klass.new(options)
    end

    describe '#request' do

      def do_auth_request
        request_name = config[:auth_service][:request].to_sym

        bootstrap = {
          auth_service: config[:auth_service]
        }

        service.request request_name, bootstrap do |params|
          config[:auth_credentials].each do |k,v|
            params[k] = v
          end
        end
      end


      it 'can find the correct request based on bootstrapped session data' do
        response = do_auth_request
      
        response.must_be_instance_of Aviator::Response
        response.request.api_version.must_equal config[:auth_service][:api_version].to_sym
      end
      
      
      it 'can find the correct request based on non-bootstrapped session data' do
        session_data = do_auth_request.body
        
        response = service.request :create_tenant, session_data do |params|
          params.name        = 'Test Project'
          params.description = 'This is a test'
          params.enabled     =  true
        end
        
        response.status.must_equal 200
      end
      
      
      it 'uses the default session data if session data is not provided' do
        default_session_data = do_auth_request.body
        s = service(default_session_data)

        response = s.request :create_tenant do |params|
          params.name        = 'Test Project Too'
          params.description = 'This is a test'
          params.enabled     =  true
        end
        
        response.status.must_equal 200
      end
      
      
      it 'raises a SessionDataNotProvidedError if there is no session data' do
        the_method = lambda do
          service.request :create_tenant do |params|
            params.name        = 'Test Project Too'
            params.description = 'This is a test'
            params.enabled     =  true
          end
        end
        
        the_method.must_raise Aviator::Service::SessionDataNotProvidedError
        error = the_method.call rescue $!
        error.message.wont_be_nil
      end

    end

  end

end