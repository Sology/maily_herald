require 'rails_helper'

describe MailyHerald::Mailing::Template do

  subject { described_class.new(mailing) }

  context "only template_plain" do
    let(:mailing) { double(MailyHerald::OneTimeMailing,
                      template_plain:  "Hello there!\nUser name: {{user.name}}.\nhttp://www.sology.eu",
                      template_html:   nil) }

    it { expect(subject.plain).to eq(mailing.template_plain) }
    it { expect(subject.html).to eq("Hello there!<br/>User name: {{user.name}}.<br/><a href=http://www.sology.eu>http://www.sology.eu</a>") }
  end

  context "only template_html" do
    let(:mailing) { double(MailyHerald::OneTimeMailing,
                      template_plain:  nil,
                      template_html:   "<h1>Subtitle<h1>\n<p>One Time mailing's body</p><a href=http://www.sology.eu>http://www.sology.eu</a>") }

    it { expect(subject.plain).to eq("Subtitle\nOne Time mailing's body\nhttp://www.sology.eu") }
    it { expect(subject.html).to eq(mailing.template_html) }
  end

  context "combined" do
    let(:mailing) { double(MailyHerald::OneTimeMailing,
                      template_plain:  "Hello there!\nUser name: {{user.name}}.\nhttp://www.sology.eu",
                      template_html:   "<h1>Subtitle<h1>\n<p>One Time mailing's body</p><a href=http://www.sology.eu>http://www.sology.eu</a>") }

    it { expect(subject.plain).to eq(mailing.template_plain) }
    it { expect(subject.html).to eq(mailing.template_html) }
  end

end
