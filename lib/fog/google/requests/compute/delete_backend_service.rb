module Fog
  module Compute
    class Google
      class Mock
        def delete_backend_service(backend_service_name)
          Fog::Mock.not_implemented
        end
      end

      class Real

        def delete_backend_service(backend_service_name)
          api_method = @compute.backend_services.delete
          parameters = {
            'project' => @project,
            'backendService' => backend_service_name
          }
          request(api_method, parameters)
        end
      end
    end
  end
end
