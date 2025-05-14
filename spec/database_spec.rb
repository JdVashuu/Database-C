describe 'database' do
  # Use a constant for the test database name
  TEST_DB_NAME = 'test.db'

  # Before each test, ensure the database is clean
  before do
    # Properly delete the test database file before each test
    File.delete(TEST_DB_NAME) if File.exist?(TEST_DB_NAME)
  end

  # After all tests, clean up the test database
  after(:all) do
    File.delete(TEST_DB_NAME) if File.exist?(TEST_DB_NAME)
  end

  def run_script(commands)
    raw_output = nil
    begin
      IO.popen("./db #{TEST_DB_NAME}", "r+") do |pipe|
        commands.each do |command|
          pipe.puts(command)
        end
        pipe.close_write

        raw_output = pipe.gets(nil)
      end
      raw_output.split("\n")
    rescue => e
      puts "Error executing database commands: #{e.message}"
      puts e.backtrace
      []
    end
  end

  it 'insert and retrieves a row' do
    result = run_script([
      "insert 1 user1 person1@example.com",
      "select",
      ".exit",
    ])
    expect(result).to match_array([
      "db > Executed.",
      "db > (1, user1, person1@example.com)",
      "Executed.",
      "db > ",
    ])
  end

  it 'prints error message when table is full' do
    script = (1..1401).map do |i|
      "insert #{i} user#{i} person#{i}@example.com"
    end
    script << ".exit"
    result = run_script(script)
    expect(result[-2]).to eq('db > Error : Table full!')
  end

  it 'allows inserting strings that are the maximum length' do
    long_username = "a"*32
    long_email = "a"*255
    script = [
      "insert 1 #{long_username} #{long_email}",
      "select",
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "db > Executed.",
      "db > (1, #{long_username}, #{long_email})",
      "Executed.",
      "db > ",
    ])
  end

  it 'prints error message if strings are too long' do
    long_username = "a"*33
    long_email = "a"*256
    script = [
      "insert 1 #{long_username} #{long_email}",
      "select",
      ".exit",
    ]
    result = run_script(script)
    expect(result).to match_array([
      "db > String is too long.",
      "db > Executed.",
      "db > ",
    ])
  end

  it 'prints an error message if id is negative' do
    script = [
      "insert -1 cstack foo@bar.com",
      "select",
      ".exit",
    ]

    result = run_script(script)
    expect(result).to match_array([
      "db > ID must be positive." ,
      "db > Executed.",
      "db > ",
    ])
  end

  it 'keeps data after closing connection' do
    result1 = run_script([
      "insert 1 user1 person1@example.com",
      ".exit",
    ])
    expect(result1).to match_array([
      "db > Executed.",
      "db > ",
    ])
    result2 = run_script([
      "select",
      ".exit",
    ])
    expect(result2).to match_array([
      "db > (1, user1, person1@example.com)",
      "Executed.",
      "db > ",
    ])
  end
end
