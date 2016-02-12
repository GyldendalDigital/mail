# encoding: utf-8
require 'spec_helper'

describe "Round Tripping" do

  it "should round trip a basic email" do
    mail = Mail.new('Subject: FooBar')
    mail.body "This is Text"
    parsed_mail = Mail.new(mail.to_s)
    parsed_mail.subject.to_s.should eq "FooBar"
    parsed_mail.body.to_s.should eq "This is Text"
  end

  it "should round trip a html multipart email" do
    mail = Mail.new('Subject: FooBar')
    mail.text_part = Mail::Part.new do
      body "This is Text"
    end
    mail.html_part = Mail::Part.new do
      content_type "text/html; charset=US-ASCII"
      body "<b>This is HTML</b>"
    end
    parsed_mail = Mail.new(mail.to_s)
    parsed_mail.mime_type.should eq 'multipart/alternative'
    parsed_mail.boundary.should eq mail.boundary
    parsed_mail.parts.length.should eq 2
    parsed_mail.parts[0].body.to_s.should eq "This is Text"
    parsed_mail.parts[1].body.to_s.should eq "<b>This is HTML</b>"
  end

  it "should round trip string encoding for a basic email with UTF-8 characters" do
    original_subject = 'Subject: Blåbærsyltetøy'
    original_body = "This is an email with UTF-8 letters æøåÆØÅ"
    expect(original_subject.encoding).to eq Encoding::UTF_8
    expect(original_body.encoding).to eq Encoding::UTF_8

    mail = Mail.new(original_subject)
    mail.charset = 'UTF-8'
    mail.body original_body
    parsed_mail = Mail.new(mail.to_s)
    parsed_subject = parsed_mail.subject.to_s
    parsed_body = parsed_mail.body.to_s

    expect(parsed_subject.encoding).to eq original_subject.encoding
    expect(parsed_body.encoding).to eq original_body.encoding
  end

  it "should round trip string encoding for a html multipart email with UTF-8 characters" do
    original_subject = 'Subject: Blåbærsyltetøy'
    original_text_part = "This is an email with UTF-8 letters æøåÆØÅ"
    original_html_part = "This is an email with UTF-8 letters <b>æøåÆØÅ</b>"
    expect(original_subject.encoding).to eq Encoding::UTF_8
    expect(original_text_part.encoding).to eq Encoding::UTF_8
    expect(original_html_part.encoding).to eq Encoding::UTF_8

    mail = Mail.new(original_subject)
    mail.text_part = Mail::Part.new do
      content_type "text/plain; charset=UTF-8"
      body original_text_part
    end
    mail.html_part = Mail::Part.new do
      content_type "text/html; charset=UTF-8"
      body original_html_part
    end
    parsed_mail = Mail.new(mail.to_s)
    parsed_subject = parsed_mail.subject.to_s
    parsed_text_part = parsed_mail.parts[0].body.to_s
    parsed_html_part = parsed_mail.parts[1].body.to_s

    expect(parsed_subject.encoding).to eq original_subject.encoding
    expect(parsed_text_part.encoding).to eq original_text_part.encoding
    expect(parsed_html_part.encoding).to eq original_html_part.encoding
  end

  it "should round trip an email" do
    initial = Mail.new do
      to        "mikel@test.lindsaar.net"
      subject   "testing round tripping"
      body      "Really testing round tripping."
      from      "system@test.lindsaar.net"
      cc        "nobody@test.lindsaar.net"
      bcc       "bob@test.lindsaar.net"
      date      Time.local(2009, 11, 6)
      add_file  :filename => "foo.txt", :content => "I have \ntwo lines\n\n"
    end
    Mail.new(initial.encoded).encoded.should eq initial.encoded
  end

  it "should round trip attachment newlines" do
    body = "I have \ntwo lines\n\n"
    initial = Mail.new
    initial.add_file :filename => "foo.txt", :content => body
    Mail.new(initial.encoded).attachments.first.decoded.should eq body
  end
end
