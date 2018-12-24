class Mailer < ActionMailer::Base
  def misc(from, to, subject, body, is_html)
    @subject    = subject
    @from       = from
    @recipients = to
    @sent_on    = Time.now
    @headers    = {}
    
    content_type("text/html") if is_html
    
    @body['content'] = body
  end
end
