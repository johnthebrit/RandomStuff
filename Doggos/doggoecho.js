// to execute
// node doggoecho.js 3000 10.0.1.5

'use strict';

const PORT = parseInt(process.argv[2]) || 3000;
const HOST = process.argv[3] || '127.0.0.1';

const http = require('http');


try {

	const server = http.createServer((req,res) => {
	
		let body = '';
		req.on('data',(chunk) => {
			body += chunk;
		});
		
		req.on('end',() => {

			res.setHeader("content-type","text/html");

            res.write(`<html><body>Authenticated as <b> ${req.headers['userupn']} </b> ( ${req.headers['userdisplayname']} ) \n`);
			res.write("<img src='https://savilltech.com/images/zerosniffs.png'/><pre>");
            res.write('Debug Information:\n************************\n');
            res.write(`HTTP Version :  ${req.httpVersion} \n`);
            res.write(`Method :   ${req.method} \n`);
            res.write(`URL Path :  ${req.url} \n`);
            
    
            res.write("\n******* Headers ********\n");
            for(let header in req.headers)
			{
                if (header !== 'x-forwarded-for') {
					res.write(`${header} :  ${req.headers[header]} \n`);
				}
				
			}
            //res.write('\n********* Body *********\n');
            //res.write(body);

            //res.write('\n********* Time *********\n');
            //res.write(Date.now().toString());
            //res.write('\n\n************************\n');
            res.write("</pre></body></html>")


            res.end();
		});
		
	});


	server.listen(PORT,HOST,() => {
		console.log(`Echo Server listening on ${HOST}:${PORT} ...`);
	});	

} catch (error) {
	console.error(`Error Starting Server : ${error.message}`);
}