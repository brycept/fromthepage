class Metadata
  def initialize(metadata_file:, collection:)
    @rowset_errors = []
    @new_metadata = []
    @metadata_file = metadata_file
    @collection = collection
  end

  def process_csv
    csv = CSV.open(@metadata_file)
    headers = csv.shift
    rows = CSV.parse(@metadata_file).map { |a| Hash[ headers.zip(a) ] }
    rows.shift

    # process rows.
    rows.each do |rs|
      rs.each do |r|
        @new_metadata << { label: r[0],  value: r[1] }
      end

      begin
        work = Work.find(rs['work_id'].to_i)
        work.update(original_metadata: @new_metadata.to_json)

        unless @collection.works.include?(work)
          @rowset_errors << { error: "No work with ID #{rs['work_id']} is in collection #{@collection.title}",
                              work_id: rs['work_id'],
                              title: rs['title'] }
        end
      rescue ActiveRecord::RecordNotFound
        @rowset_errors << { error: "No work exists with ID #{rs['work_id']}",
                            work_id: rs['work_id'],
                            title: rs['title'] }

        # write the error.csv to the filesystem.
        output_file(@rowset_errors)
      end
    end

    result = { content: rows, errors: @rowset_errors }
    result
  end

  def output_file(rowset_errors)
    CSV.open('/tmp/error.csv', 'wb') do |csv|

      rowset_errors.each do |re|
        csv << [re[:error], re[:work_id], re[:title]]
      end
    end
  end

  def self.retrieve_error
    rows = CSV.parse(File.open('/tmp/error.csv'))

    # delete the file after we are done reading it.
    File.delete('/tmp/error.csv')

    csv_string = CSV.generate(headers: true) do |csv|
      csv << ['error', 'work_id', 'title']

      rows.each do |r|
        csv << r
      end
    end

    csv_string
  end

  def self.create_example(collection)
    csv_string = CSV.generate(headers: true) do |csv|
      csv << ['work_id', 'title', 'your metadata_field_one', 'your_metadata_field_two']

      collection.works.each do |work|
        csv << [work.id, work.title]
      end
    end

    csv_string
  end
end
