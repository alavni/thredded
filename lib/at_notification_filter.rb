module AtNotificationFilter
  def filtered_content
    @filtered_content = AtUsers.render(super, messageboard).html_safe
  end
end
