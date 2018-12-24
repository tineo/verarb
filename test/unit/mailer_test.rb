require File.dirname(__FILE__) + '/../test_helper'
require 'mailer'

class MailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_assign_design
    @expected.subject = 'Mailer#assign_design'
    @expected.body    = read_fixture('assign_design')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_assign_design(@expected.date).encoded
  end

  def test_assign_planning
    @expected.subject = 'Mailer#assign_planning'
    @expected.body    = read_fixture('assign_planning')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Mailer.create_assign_planning(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
