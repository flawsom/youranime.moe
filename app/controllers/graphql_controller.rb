# frozen_string_literal: true
class GraphqlController < ActionController::API
  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    country = request.headers['X-Country']
    timezone = request.headers['X-Timezone']

    context = {
      hostname: hostname,
      country: country || 'CA',
      timezone: timezone || 'America/Toronto',
      is_default: country.blank? || timezone.blank?,
      current_user: current_user,
    }
    result = TanoshimuNewSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render(json: result)
  rescue => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  def hostname
    Rails.application.config.x.graphql_host || request.protocol + request.host_with_port
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error(e.message)
    logger.error(e.backtrace.join("\n"))

    render(json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500)
  end

  def current_user
    return @current_user if @current_user.present?

    proxied_auth_uuid = request.headers['X-Proxied-Auth-ID']
    return unless proxied_auth_uuid.present?

    @current_user ||= GraphqlUser.find_or_create_by(uuid: proxied_auth_uuid)
  end
end
