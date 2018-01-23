require 'rails_helper'
require 'mail'

describe MailyHerald::Mailing::Preview do

  let(:entity)  { create :user }
  let(:mailing) { create :ad_hoc_mailing }

  context "for entity" do
    let(:preview) { MailyHerald::Mailing::Preview.new mailing.build_mail(entity) }

    describe "initial" do
      it { expect(MailyHerald::Log.count).to eq(0) }
      it { expect(preview).to be_kind_of(MailyHerald::Mailing::Preview) }
    end

    describe "#mail" do
      it { expect(preview.mail).not_to be_nil }
      it { expect(preview.mail.parts).not_to be_empty }
      it { expect(preview.mail.html_part).not_to be_nil }
      it { expect(preview.mail.html_part.body.raw_source).not_to be_empty }
      it { expect(preview.mail.text_part).not_to be_nil }
      it { expect(preview.mail.text_part.body.raw_source).not_to be_empty }
    end

    describe "#html?" do
      it { expect(preview.html?).to be_truthy }
    end

    describe "#html" do
      it { expect(preview.html.include?("<h1>Hello</h1>")).to be_truthy }
    end

    describe "#plain?" do
      it { expect(preview.plain?).to be_truthy }
    end

    describe "#plain" do
      it { expect(preview.plain.include?("Hello")).to be_truthy }
    end
  end

  context "for MailyHerald::Log" do
    let!(:log)    { MailyHerald::Log.create_for mailing, entity, {status: :scheduled} }
    let(:preview) { log.preview }

    describe "initial" do
      it { expect(log).to be_valid }
      it { expect(log.entity).to eq(entity) }
      it { expect(log.mailing).to eq(mailing) }
      it { expect(MailyHerald::Log.count).to eq(1) }
      it { expect(preview).to be_kind_of(MailyHerald::Mailing::Preview) }
    end

    context "scheduled" do
      describe "#mail" do
        it { expect(preview.mail).not_to be_nil }
        it { expect(preview.mail.parts).not_to be_empty }
        it { expect(preview.mail.html_part).not_to be_nil }
        it { expect(preview.mail.html_part.body.raw_source).not_to be_empty }
        it { expect(preview.mail.text_part).not_to be_nil }
        it { expect(preview.mail.text_part.body.raw_source).not_to be_empty }
      end

      describe "#html?" do
        it { expect(preview.html?).to be_truthy }
      end

      describe "#html" do
        it { expect(preview.html.include?("<h1>Hello</h1>")).to be_truthy }
      end

      describe "#plain?" do
        it { expect(preview.plain?).to be_truthy }
      end

      describe "#plain" do
        it { expect(preview.plain.include?("Hello")).to be_truthy }
      end
    end

    context "delivered" do
      let!(:log)    { MailyHerald::Log.create_for mailing, entity, {status: :delivered} }
      
      before do
        log.data = {
          content: "Date: Fri, 19 Jan 2018 09:26:02 +0100\r\nFrom: hello@mailyherald.org\r\nTo: #{entity.email}\r\nMessage-ID: <5a61ab5abfb3_e1a22c6e90247c7@pc.mail>\r\nSubject: Test\r\nMime-Version: 1.0\r\nContent-Type: multipart/alternative;\r\n boundary=\"--==_mimepart_5a61ab9a7d74_e1a22c6e902469\";\r\n charset=UTF-8\r\nContent-Transfer-Encoding: 7bit\r\n\r\n\r\n----==_mimepart_5a61ab9a7d74_e1a22c6e902469\r\nContent-Type: text/plain;\r\n charset=UTF-8\r\nContent-Transfer-Encoding: 7bit\r\n\r\nHello\r\n\r\n----==_mimepart_5a61ab9a7d74_e1a22c6e902469\r\nContent-Type: text/html;\r\n charset=UTF-8\r\nContent-Transfer-Encoding: 7bit\r\n\r\n<h1>Hello</h1>\r\n<img alt=\"\" id=\"tracking-pixel\" src=\"http://localhost:3000/tokens/tgViJTWKwP72f1CRrpVFVnzavC7EZ40f/open.gif\" width=\"1\" height=\"1\" />\r\n----==_mimepart_5a61ab9a7d74_e1a27c6e902469--\r\n"
        }
        log.save!
        log.reload
      end

      describe "#mail" do
        it { expect(preview.mail).not_to be_nil }
        it { expect(preview.mail.parts).not_to be_empty }
        it { expect(preview.mail.html_part).not_to be_nil }
        it { expect(preview.mail.html_part.body.raw_source).not_to be_empty }
        it { expect(preview.mail.text_part).not_to be_nil }
        it { expect(preview.mail.text_part.body.raw_source).not_to be_empty }
      end

      describe "#html?" do
        it { expect(preview.html?).to be_truthy }
      end

      describe "#html" do
        it { expect(preview.html.include?("<h1>Hello</h1>")).to be_truthy }
      end

      describe "#plain?" do
        it { expect(preview.plain?).to be_truthy }
      end

      describe "#plain" do
        it { expect(preview.plain.include?("Hello")).to be_truthy }
      end
    end
  end
end
