require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  phone = phone.tr('^0-9','').to_i
  if phone.digits.count < 10 || phone.digits.count > 11
    return "Invalid phone number"
  elsif phone.digits.count == 11
    if phone.digits[10].to_s == '1'
      return phone.to_s[1..-1]
    else
      return "Invalid phone number" 
    end
  end
  phone.to_s
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def peak_registration_hours(csv)
  # Create hash to store occurences
  occurences = Hash.new(0)

  # Loop over CSV file and count occuerneces of the hours of registration
  csv.each do |row|
    hour = Time.strptime(row[:regdate], '%m/%d/%y %H:%M').hour
    occurences[hour] += 1
  end

  # Calculate the max occurence
  max_occurence = occurences.values.max
  puts "Peak Hours for Registration:"
  occurences.each do |value|
    if value[1] == max_occurence
      puts value[0]
    end
  end
end

def peak_registration_day(csv)
  
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)

peak_registration_hours(contents)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone_number(row[:homephone])

  form_letter = erb_template.result(binding)

  #save_thank_you_letter(id, form_letter)
  #puts phone
end