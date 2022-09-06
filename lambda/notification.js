const https = require('https')

function postRequest(body) {
  const options = {
    hostname: 'discord.com',
    path: `/api/webhooks/${process.env.WEBHOOK_ID}/${process.env.WEBHOOK_TOKEN}`,
    method: 'POST',
    port: 443,
    headers: {
      'Content-Type': 'application/json',
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, () => {});
    req.write(JSON.stringify(body));
    req.end();
  });
}

exports.handler = async (event, _, callback) => {
    const data = JSON.parse(event.Records[0].Sns.Message).detail
  
    postRequest({
      embeds: [{
        description: `pipeline: \`${data.pipeline}\`\nstate: \`${data.state}\`\nstage: \`${data.stage}\``,
        color: data.state === "SUCCEEDED" ? 0x00ff00 : 0xff0000
      }]
    })
    
    callback(null, "Success");
};
