## Why is certificate installation required?

As the Postwoman application is a progressive web app, it must be served over HTTPS in order to be accessed.
This means that to allow access to the proxy via AJAX, the proxy must *also* be served over HTTPS.

Naturally, if the proxy is set up locally, this can be an issue - as most people do not want to spend time setting up a self-signed certificate.

In order to overcome this issue, the ProxyServer application generates a self-signed certificate and key on startup. The generated certificate has a Subject Alternative Name (SAN) exclusively for `127.0.0.1` allowing it to act as a trusted root solely for that local IP address.

Once the certificate is marked as trusted, the proxy can operate over HTTPS on your local device and therefore be used by Postwoman.

## How do I install the certificate?
- [macOS](#macos)
- [Windows](#windows)
- Linux (TODO)

### macOS
1. When you open the ProxyServer application for the first time, it will generate a certificate specifically for your machine. You will see the following dialog and a Finder window showing the directory with the generated Certificate:
![Postwoman Installation Process Prompt](https://user-images.githubusercontent.com/43181178/70390270-32b59480-198f-11ea-9576-bcb0a3225d5d.png)

2. Double click the file named `cert.pem`. It will open in Keychain Access.
![Keychain Access Certificate Installation Prompt](https://user-images.githubusercontent.com/43181178/70390312-81632e80-198f-11ea-9196-60ba85d8ab9e.png)

3. Click 'Add' and then search for 'The Postwoman Project' in Keychain Access.
![Keychain Access Search: 'The Postwoman Project'](https://user-images.githubusercontent.com/43181178/70390335-a9529200-198f-11ea-8d22-a9a33b90b5dd.png)

4. Double-click the certificate, and in the dialog that opens, expand the 'Trust' section by clicking the arrow to the left of the 'Trust' label. (See the red circle.)
![Keychain Access: Expand Trust Section](https://user-images.githubusercontent.com/43181178/70390366-fb93b300-198f-11ea-89b0-950ac6c37e46.png)

5. Change the 'Secure Sockets Layer (SSL)' option to 'Always Trust'. Then close the window. *Upon closing the window, you will be prompted to enter your password - and then the new settings will be saved.*
![](https://user-images.githubusercontent.com/43181178/70390410-53cab500-1990-11ea-8c7c-77b1a6efaf34.png)

6. You can now close the opened Finder window and press 'OK' in the ProxyServer dialog. You should now test the installation was successful by visiting [https://127.0.0.1:9159](https://127.0.0.1:9159) in the browser.
![Browser](https://user-images.githubusercontent.com/43181178/70390468-ee2af880-1990-11ea-99bb-852b4fa0906c.png)

7. You have now (hopefully) installed the Postwoman certificate successfully... Happy debugging!

### Windows
1. When you open the ProxyServer application for the first time, it will generate a certificate specifically for your machine. You will see the following dialog and a window showing the generated certificate:  
![Certificate Installation Prompt](https://user-images.githubusercontent.com/43181178/71110051-72198780-21be-11ea-8a05-0ecce8ba8893.png)

2. Click 'Install Certificate...', the Certificate Import Wizard will open. **Ensure that Local Machine is selected**, and then click Next.  
![Certificate Import Wizard](https://user-images.githubusercontent.com/43181178/71110263-da686900-21be-11ea-9798-98f10905d007.png)

3. Select 'Place all certificates in the following store' and then click 'Browse...'  
![Certificate Store Selection: Browse](https://user-images.githubusercontent.com/43181178/71110404-1ef40480-21bf-11ea-9b70-b6f2684baf66.png)

4. Select the 'Trusted Root Certification Authorities' store, and click OK.
![Trusted Root Certification Authorities](https://user-images.githubusercontent.com/43181178/71110615-9033b780-21bf-11ea-88f4-de88f29eb310.png)

5. Click 'Next' and then click 'Finish'.  
![Click 'Next' and then click 'Finish'](https://user-images.githubusercontent.com/43181178/71110742-ca9d5480-21bf-11ea-8b8a-fa9c20300e8e.png)

6. You can now close any confirmation dialogs and the certificate window and click 'OK' on the Postwoman dialog. You should now test the installation was successful by visiting [https://127.0.0.1:9159](https://127.0.0.1:9159) in the browser.
![Browser](https://user-images.githubusercontent.com/43181178/71110947-35e72680-21c0-11ea-9641-11e9b8958b00.png)

7. You have now (hopefully) installed the Postwoman certificate successfully... Happy debugging!