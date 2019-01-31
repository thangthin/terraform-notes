const AWS = require('aws-sdk');
//*/ get reference to S3 client 
const s3 = new AWS.S3();

exports.handler = async (event, context) => {
    const params = {
      Bucket: "tmt-pictures", 
      Key: "image.png"
     };
     
    let req = s3.getObject(params).promise();
    let data = await req;
    let encodedBody = data.Body.toString('base64');
    
    let response = {
        statusCode: 200,
        headers: 
           {
             "Content-Type": "image/png",
             "X-Custom-Thang": "test/headeer/value"
           },
        body: encodedBody,
        isBase64Encoded: true
    };
    
    return response;
};
