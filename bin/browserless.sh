post_url=""
api_url=""
websocket_url=""
chat_room_channel_id=""

curl -X POST \
  "$post_url" \
  -H "Content-Type: application/javascript" \
  -d "export default async function ({ page }) {
  return new Promise(async (resolve, reject) => {
    const apiUrl = \"$api_url\";
    const websocketUrl = \"$websocket_url\";

    const socket = new WebSocket(websocketUrl);

    let titles = [];

    socket.onopen = function(event) {
      const msg = {
        command: \"subscribe\",
        identifier: JSON.stringify({
          id: \"$chat_room_channel_id\",
          channel: \"ChatRoomChannel\"
        }),
      };
      socket.send(JSON.stringify(msg));
    };

    socket.onmessage = async function(event) {
      const response = event.data;
      const msg = JSON.parse(response);

      if (msg.message && msg.message.content === \"done\") {
        return resolve({
          data: {
            titles: titles,
          },
          type: \"application/json\",
        });
      }

      if (msg.message && /Visit complete for/.test(msg.message.content)) {
        return;
      }

      if (msg.message && typeof(msg.message) === \"object\") {
        let url = msg.message.content;

        await page.goto(url);

        let title = await page.title();

        titles.push(title);

        fetch(apiUrl + 'messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              content: 'Visit complete for ' + title,
              chat_room_id: \"$chat_room_channel_id\",
            },
          }),
        });
      }
    };

    socket.onerror = function(error) {
      if (error.message) {
        reject(error.message);
      } else {
        reject(\"WebSocket connection error\");
      }
    };

  });
}"
