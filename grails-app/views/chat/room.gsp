<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
  <title>Home</title>
  <meta name="layout" content="main">
  <asset:javascript src="spring-websocket" />
  <script src="//cdn.webrtc-experiment.com/RTCMultiConnection.js"></script>
  <script>
    var _urlify = function(text) {
      var urlRegex = /((?:(http|https|Http|Https|rtsp|Rtsp):\/\/(?:(?:[a-zA-Z0-9\$\-\_\.\+\!\*\'\(\)\,\;\?\&\=]|(?:\%[a-fA-F0-9]{2})){1,64}(?:\:(?:[a-zA-Z0-9\$\-\_\.\+\!\*\'\(\)\,\;\?\&\=]|(?:\%[a-fA-F0-9]{2})){1,25})?\@)?)?((?:(?:[a-zA-Z0-9][a-zA-Z0-9\-]{0,64}\.)+(?:(?:aero|arpa|asia|a[cdefgilmnoqrstuwxz])|(?:biz|b[abdefghijmnorstvwyz])|(?:cat|com|coop|c[acdfghiklmnoruvxyz])|d[ejkmoz]|(?:edu|e[cegrstu])|f[ijkmor]|(?:gov|g[abdefghilmnpqrstuwy])|h[kmnrtu]|(?:info|int|i[delmnoqrst])|(?:jobs|j[emop])|k[eghimnrwyz]|l[abcikrstuvy]|(?:mil|mobi|museum|m[acdghklmnopqrstuvwxyz])|(?:name|net|n[acefgilopruz])|(?:org|om)|(?:pro|p[aefghklmnrstwy])|qa|r[eouw]|s[abcdeghijklmnortuvyz]|(?:tel|travel|t[cdfghjklmnoprtvwz])|u[agkmsyz]|v[aceginu]|w[fs]|y[etu]|z[amw]))|(?:(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9])))(?:\:\d{1,5})?)(\/(?:(?:[a-zA-Z0-9\;\/\?\:\@\&\=\#\~\-\.\+\!\*\'\(\)\,\_])|(?:\%[a-fA-F0-9]{2}))*)?(?:\b|$)/gi;

      return text.replace(urlRegex, function(url) {
        if (!url.substr(0, 4).match(/(http|Http|rtsp|Rtsp)/)) {
          url = "http://" + url;
        }
        return '<a href="' + url + '" target="_blank">' + url + '</a>';
      });
    };

    var _connectVideoAndAudio = function() {
      var connection = new RTCMultiConnection();

      connection.session = {
        audio: true,
        video: true
      };

      connection.onstream = function(e) {
        $("#chat-video").append(e.mediaElement);
      };

      connection.connect();

      document.querySelector('#enable-video-button').onclick = function() {
        connection.open();
      };
    };

    $(function() {
      var socket = new SockJS("${createLink(uri: '/stomp')}");
      var client = Stomp.over(socket);

      var chatLog = $("#chat-log");
      var chatText = $("#chat-text");
      var chatRoom = $("#chatroom");

      client.connect({}, function() {
        client.subscribe("/topic/chatMessage", function(message) {
          chatLog.append("<div class='chat-text'>" + _urlify(JSON.parse(message.body)) + '</div>');
          chatLog.animate({ scrollTop: chatLog.prop("scrollHeight") - chatLog.height() }, 200);
        });
      });

      var username = $("#username");
      var modal = $("#usernameModal");
      var enterRoom = $("#enter-room-button");
      modal.modal();

      username.keyup(function() {
        if ($.trim(username.val()) !== "") {
          enterRoom.removeAttr("disabled");
        } else {
          enterRoom.attr("disabled", "disabled");
        }
      });

      enterRoom.click(function() {
        if ($.trim(username.val()) === "") {
          username.val("");
          username.focus();
          return false;
        }

        modal.modal('hide');
        client.send("/app/chatMessage", {}, JSON.stringify(username.val() + " has entered the chatroom."));
        _connectVideoAndAudio();
      });

      chatText.keypress(function(event) {
        if (event.keyCode == 13) {
          event.preventDefault();
          if ($.trim(chatText.val()) !== "") {
            client.send("/app/chatMessage", {}, JSON.stringify(username.val() + ": " + chatText.val()));
            chatText.val("");
          }
        }
      });

      chatLog.height(chatRoom.height() - 90);
      $(window).resize(function() {
        chatLog.height(chatRoom.height() - 90);
      });
    });
  </script>
</head>

<body>
<div id="chatroom">
  <div>
    <button id="enable-video-button" class="btn btn-primary">Enable Video</button>
  </div>
  <div id="chat-video">

  </div>
  <div id="chat-log">
  </div>
  <textarea id="chat-text" placeholder="Type to chat..."></textarea>
</div>
<g:render template="usernameModal" />
</body>
</html>