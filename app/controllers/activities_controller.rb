class ActivitiesController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json {
        from = params[:from] || 0
        page_size = 20
        filter = {}
        options = {}

        if params[:since].present?
          start_date = Time.now.utc - params[:since].to_i.hours
          options[:since] = start_date
          filter = {range: {"@start" => {gte: start_date.iso8601}}}
        end

        if params[:ranges].present?
          all_filters = params[:ranges].values.map do |range_filter|
            filter = {range: {range_filter['name'] => {gte: range_filter['range']['from'], lt: range_filter['range']['to']}}}
          end
          all_filters << filter if filter.present?
          filter = {and: all_filters}
        end

        begin
          result = Hercule::Activity.query(params[:q], {from: from, size: page_size, filter: filter}, options).with_levels
          render json: { result: 'ok', activities: result.items, total: result.total }.to_json
        rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
          response = JSON.parse(e.message[6..-1])
          render json: { result: 'error', body: response['error'] }.to_json
        end
      }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        main = Hercule::Activity.find(params[:date], params[:id])

        if main
          data = [main]

          children = [main]
          while not children.empty?
            ids = children.map(&:id)
            children = Hercule::Activity.find_by_parents(params[:date], ids)
            data = data + children
          end
        else
          data = []
        end

        Hercule::Activity.bulk_load_entries(data)
        render json: data.as_json(with_entries: true)
      }
    end
  end
end

