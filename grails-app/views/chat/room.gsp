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
        var videos = $("#chat-video video");
        videos.width(($("#chatroom").width() - $("#chat-log").width()) / videos.length - 20);
      };

      connection.connect();

      document.querySelector('#enable-video').onclick = function() {
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
        client.send("/app/chatMessage", {}, JSON.stringify(username.val() + " has entered the chatroom.|${chatroom.uniqueId}" ));
        _connectVideoAndAudio();
      });

      chatText.keypress(function(event) {
        if (event.keyCode == 13) {
          event.preventDefault();
          if ($.trim(chatText.val()) !== "") {
            client.send("/app/chatMessage", {}, JSON.stringify(username.val() + ": " + chatText.val() + "|${chatroom.uniqueId}"));
            chatText.val("");
          }
        }
      });

      $("#exit-chatroom").click(function() {
        if (confirm("Are you sure you'd like to exit the chatroom?")) {
          client.send("/app/chatMessage", {}, JSON.stringify(username.val() + " has left the chatroom.|${chatroom.uniqueId}"));
          client.disconnect();
          window.location.href = "/" + config.application.name;
        }
      });

      chatLog.height(chatRoom.height() - 70);
      $(window).resize(function() {
        chatLog.height(chatRoom.height() - 70);
      });

      chatLog.html(_urlify(chatLog.html()));

      var copyButton = $("#chat-copy-url");
      var zc = new ZeroClipboard(copyButton);

      zc.on("ready", function(readyEvent) {
        zc.on("aftercopy", function(event) {
          alert("URL copied to clipboard!");
        });
      });

      $("#toggle-chat").click(function() {
        if (chatLog.css("right") === "-300px") {
          chatLog.animate({ right: 0 }, 200);
          chatText.animate({ right: 0 }, 200);
          return;
        }
        chatLog.animate({ right: -300 }, 200);
        chatText.animate({ right: -300 }, 200);
      });

      $("#invite-users").click(function() {
        $("#inviteUsersModal").modal();
      });

      $("#invite-users-button").click(function() {
        $(this).button('loading');
        $.ajax({
          type: "POST",
          data: {
            uniqueId: "${chatroom.uniqueId}",
            emails: $("#chatroom-emails").val()
          },
          url: "/" + config.application.name + "/chat/invite",
          success: function() {
            client.send("/app/chatMessage", {}, JSON.stringify(username.val() + " invited the following users to the chatroom: " + $("#chatroom-emails").val() + "|${chatroom.uniqueId}"));
            $("#chatroom-emails").val("");
            $("#inviteUsersModal").modal('hide');
            $(this).button('reset');
          },
          error: function(data) {
            alert(data.responseJSON.message);
            $(this).button('reset');
          }
        });
      });
    });
  </script>
</head>

<body>
<div id="chatroom">
  <div>
  </div>
  <div id="chat-video"></div>
  <div id="chat-log"><lochchat:logHtml logInstance="${chatroom.log}" /></div>
  <textarea id="chat-text" placeholder="Type to chat..."></textarea>
  <div id="chat-options">
    <div class="chat-option">
      <asset:image id="chat-copy-url" data-clipboard-text="${chatroom.url}" src="flat-icons/Icons/Set 2/PNG/4.png" />
      <label>Copy URL</label>
    </div>
    <div class="chat-option">
      <asset:image id="toggle-chat" src="flat-icons/Icons/Set 2/PNG/11.png" />
      <label>Toggle Chat</label>
    </div>
    <div class="chat-option">
      <asset:image id="enable-video" src="flat-icons/Icons/Set 2/PNG/10.png" />
      <label>Enable Video</label>
    </div>
    <div class="chat-option">
      <asset:image id="invite-users" src="flat-icons/Icons/Set 2/PNG/2.png" />
      <label>Invite Users</label>
    </div>
    <div class="chat-option">
      <g:link controller="chat" action="export" params="[uniqueId: chatroom.uniqueId]"><asset:image id="export-log" src="flat-icons/Icons/Set 3/PNG/3.png" /></g:link>
      <label>Export Chat Log</label>
    </div>
    <div class="chat-option">
      <asset:image id="exit-chatroom" src="flat-icons/Icons/Set 2/PNG/3.png" />
      <label>Exit Chatroom</label>
    </div>
  </div>
</div>
<g:render template="usernameModal" />
<g:render template="inviteUsersModal" />
</body>
</html>