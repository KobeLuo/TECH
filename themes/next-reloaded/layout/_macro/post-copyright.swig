{% if theme.post_copyright.enable %}
  <ul class="post-copyright">
    <li class="post-copyright-author">
      <strong>{{ __('post.copyright.author') + __('symbol.colon') }}</strong>
      {{ config.author }}
    </li>
    <li class="post-copyright-title">
      <strong>{{ __('本文标题') + __('symbol.colon') }}</strong>
      {{ post.title }}
    </li>
    <li class="post-copyright-link">
      <strong>{{ __('post.copyright.link') + __('symbol.colon') }}</strong>
      <a href="http://www.kobeluo.com/tech/{{ post.path }}" title="{{ post.title }}">http://www.kobeluo.com/tech/{{ post.path }}</a>
    </li>
    <li class="post-copyright-license">
      <strong>{{ __('post.copyright.license_title') + __('symbol.colon') }} </strong>
      {{ __('post.copyright.license_content', theme.post_copyright.license_url, theme.post_copyright.license) }}
    </li>
  </ul>
{% endif %}
