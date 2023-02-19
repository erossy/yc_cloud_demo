from flask import Flask, request
import os
import socket
import mysql.connector

app = Flask(__name__)

@app.route("/hello")
def helloworld():
    return "Hello World with Python Flask App server from {} to {}".format(socket.gethostname(), request.remote_addr)

@app.route('/')
def hello():
    db = mysql.connector.connect(
              host=os.getenv("db_host"),
              port="3306",
              user=os.getenv("db_user"),
              passwd=os.getenv("db_password"),
              database=os.getenv("db_name"),
              auth_plugin="mysql_native_password"
         )
    cursor = db.cursor()
    cursor.execute('CREATE TABLE IF NOT EXISTS `table2` (id INT)')
    cursor.execute("INSERT INTO table2 (id) VALUES (15)")
    db.commit()
    return "Hostname {} successfully inserted a value into SQL table on {} managed SQL DB".format(socket.gethostname(), os.getenv("db_host"))
