require 'spec_helper'

describe TopicDecorator, '#css_class' do
  it 'builds a class with locked if the topic is locked' do
    topic = build_stubbed(:topic, locked: true)
    decorated_topic = TopicDecorator.new(topic)

    expect(decorated_topic.css_class).to eq 'class="locked"'
  end

  it 'builds a class with sticky if the topic is sticky' do
    topic = build_stubbed(:topic, sticky: true)
    decorated_topic = TopicDecorator.new(topic)

    expect(decorated_topic.css_class).to eq 'class="sticky"'
  end

  it 'builds a class with private if the topic is private' do
    topic = build_stubbed(:private_topic)
    decorated_topic = TopicDecorator.new(topic)

    expect(decorated_topic.css_class).to eq 'class="private"'
  end

  it 'returns nothing if plain vanilla topic' do
    topic = build_stubbed(:topic)
    decorated_topic = TopicDecorator.new(topic)

    expect(decorated_topic.css_class).to eq ''
  end

  it 'returns string with several topic states' do
    topic = build_stubbed(:topic, sticky: true, locked: true)
    decorated_topic = TopicDecorator.new(topic)

    expect(decorated_topic.css_class).to eq 'class="locked sticky"'
  end
end
