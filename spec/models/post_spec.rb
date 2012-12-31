require 'spec_helper'

describe Post, 'validations' do
  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:messageboard_id) }
end

describe Post, 'associations' do
  it { should have_many(:post_notifications) }
end

describe Post, '#create' do
  before(:each) do
    Time.zone = 'UTC'
    Chronic.time_class = Time.zone
  end

  after(:each) do
    Timecop.return
  end

  it 'updates the parent topic with the latest post author' do
    joel  = create(:user)
    topic = create(:topic)
    post = create(:post, user: joel, topic: topic)

    topic.reload.last_user.should eq joel
  end

  it "increments the topic's and user's post counts" do
    joel  = create(:user)
    topic = create(:topic)

    3.times do
      topic.posts.create!(user: joel, last_user: joel, content: 'content',
        messageboard: topic.messageboard)
    end

    topic.reload.posts_count.should eq 3
    joel.reload.posts_count.should eq 3
  end

  it 'updates the topic updated_at field to that of the new post' do
    joel  = create(:user)
    topic = create(:topic)
    messageboard = topic.messageboard

    Timecop.travel(Chronic.parse('Jan 1st 2012 at noon')) do
      create(:post, topic: topic, messageboard: messageboard, user: joel, content: 'posting here')
    end

    Timecop.travel(Chronic.parse('Jan 1st 2012 at 3pm')) do
      create(:post, topic: topic, messageboard: messageboard, user: joel, content: 'posting more')
    end

    topic.updated_at.to_s.should eq Chronic.parse('Jan 1st 2012 at 3pm').to_s
  end

  it 'sets the post user email on creation' do
    shaun = create(:user)
    topic = create(:topic, last_user: shaun)
    post = create(:post, user: shaun, topic: topic)

    post.user_email.should eq post.user.email
  end
end

describe Post, '.filtered_content' do
  before(:each) do
    @post  = build(:post)
  end

  it 'converts textile to html' do
    @post.content = 'this is *bold*'
    @post.filter = 'textile'
    @post.filtered_content.should eq '<p>this is <strong>bold</strong></p>'
  end

  it 'converts bbcode to html' do
    @post.content = 'this is [b]bold[/b]'
    @post.filter = 'bbcode'
    @post.filtered_content.should eq 'this is <strong>bold</strong>'
  end

  it 'performs some syntax highlighting with bbcode' do
    input = %Q([code]def hello
puts 'world'
end[/code]

[code:javascript]function(){
console.log('hi');
}[/code])

    expected_output = %Q(<div class="CodeRay">\n  <div class="code"><pre><span class="keyword">def</span> <span class="function">hello</span>\nputs <span class="string"><span class="delimiter">'</span><span class="content">world</span><span class="delimiter">'</span></span>\n<span class="keyword">end</span></pre></div>\n</div>\n<br />\n<br />\n<div class="CodeRay">\n  <div class="code"><pre><span class="keyword">function</span>(){\nconsole.log(<span class="string"><span class="delimiter">'</span><span class="content">hi</span><span class="delimiter">'</span></span>);\n}</pre></div>\n</div>\n)

    @post.filter = 'bbcode'
    @post.content = input

    @post.filtered_content.should eq expected_output
  end

  it 'converts markdown to html' do
    @post.content = "# Header\nhttp://www.google.com"
    @post.filter = 'markdown'

    @post.filtered_content.should eq %Q(<h1>Header</h1>\n\n<p><a href="http://www.google.com">http://www.google.com</a></p>\n)
  end

  it 'performs some syntax highlighting in markdown' do
    input = "this is code

    def hello; puts 'world'; end

right here"

    expected_output = "<p>this is code</p>\n\n<div class=\"CodeRay\">\n  <div class=\"code\"><pre><span class=\"keyword\">def</span> <span class=\"function\">hello</span>; puts <span class=\"string\"><span class=\"delimiter\">'</span><span class=\"content\">world</span><span class=\"delimiter\">'</span></span>; <span class=\"keyword\">end</span>\n</pre></div>\n</div>\n\n\n<p>right here</p>\n"

    @post.content = input
    @post.filter = 'markdown'

    @post.filtered_content.should eq expected_output
  end

  it "translates psuedo-image tags to html" do
    attachment_1 = build_stubbed(:imgpng)
    attachment_2 = build_stubbed(:pdfpng)
    attachment_3 = build_stubbed(:txtpng)
    attachment_4 = build_stubbed(:zippng)
    attachment_1.stubs(id: '4', attachment: '/uploads/attachment/4/img.png')
    attachment_2.stubs(id: '3', attachment: '/uploads/attachment/3/pdf.png')
    attachment_3.stubs(id: '2', attachment: '/uploads/attachment/2/txt.png')
    attachment_4.stubs(id: '1', attachment: '/uploads/attachment/1/zip.png')

    post = build_stubbed(:post,
      content: '[t:img=2 left] [t:img=3 right] [t:img] [t:img=4 200x200]',
      attachments: [attachment_1, attachment_2, attachment_3, attachment_4])

    expectation = "<img src=\"/uploads/attachment/3/pdf.png\" class=\"align_left\" /> <img src=\"/uploads/attachment/2/txt.png\" class=\"align_right\" /> <img src=\"/uploads/attachment/4/img.png\" /> <img src=\"/uploads/attachment/1/zip.png\" width=\"200\" height=\"200\" />"

    post.filtered_content.should == expectation
  end

  it 'links @names of members' do
    sam = build_stubbed(:user, name: 'sam')
    joe = build_stubbed(:user, name: 'joe')
    Messageboard.any_instance.stubs(members_from_list: [sam, joe])
    post = build_stubbed(:post, content: 'for @sam but not @al or @kek. And @joe.')
    expectation = 'for <a href="/users/sam">@sam</a> but not @al or @kek. And <a href="/users/joe">@joe</a>.'

    post.filtered_content.should eq expectation
  end
end
