package main

import (
	"github.com/atotto/clipboard"
	"github.com/getlantern/systray"
	"github.com/pkg/browser"

	icon "github.com/devsolux/proxyserver/icons"
	"github.com/devsolux/proxyserver/inputbox"
	"github.com/devsolux/proxyserver/libproxy"
	"github.com/devsolux/proxyserver/notifier"
)

var (
	VersionName string
	VersionCode string
)

var (
	mStatus          *systray.MenuItem
	mCopyAccessToken *systray.MenuItem
)

func main() {
	systray.Run(onReady, onExit)
}

func onReady() {
	systray.SetIcon(icon.Data)
	systray.SetTooltip("Proxyserver v" + VersionName + " (" + VersionCode + ")")

	/** Set up menu items. **/

	// Status
	mStatus = systray.AddMenuItem("Starting...", "")
	mStatus.Disable()
	mCopyAccessToken = systray.AddMenuItem("Copy Access Token...", "")
	mCopyAccessToken.Disable()

	systray.AddSeparator()

	// Set Proxy Authentication Token
	mSetAccessToken := systray.AddMenuItem("Set Access Token...", "")
	// Check for Updates
	mUpdateCheck := systray.AddMenuItem("Check for Updates...", "")

	systray.AddSeparator()

	// Quit Proxy
	mQuit := systray.AddMenuItem("Quit Proxyserver", "")

	/** Start proxy server. **/
	go runProxy()

	/** Wait for menu input. **/
	for {
		select {
		case <-mCopyAccessToken.ClickedCh:
			_ = clipboard.WriteAll(libproxy.GetAccessToken())
			_ = notifier.Notify("Proxyserver", "Proxy Access Token copied...", "The Proxy Access Token has been copied to your clipboard.", notifier.GetIcon())

		case <-mSetAccessToken.ClickedCh:
			newAccessToken, success := inputbox.InputBox("Proxyserver", "Please enter the new Proxy Access Token...\n(Leave this blank to disable access checks.)", "")
			if success {
				libproxy.SetAccessToken(newAccessToken)

				if len(newAccessToken) == 0 {
					_ = notifier.Notify("Proxyserver", "Proxy Access check disabled.", "**Anyone can access your proxy server!** The Proxy Access Token check has been disabled.", notifier.GetIcon())
				} else {
					_ = notifier.Notify("Proxyserver", "Proxy Access Token updated...", "The Proxy Access Token has been updated.", notifier.GetIcon())
				}
			}

		case <-mUpdateCheck.ClickedCh:
			// TODO: Add update check.
			_ = browser.OpenURL("https://github.com/devsolux/proxyserver")

		case <-mQuit.ClickedCh:
			systray.Quit()
			return
		}
	}
}

func onExit() {
}

func runProxy() {
	libproxy.Initialize("devsolux", "127.0.0.1:9159", "https://devsolux.com", "", "", onProxyStateChange, true, nil)
}

func onProxyStateChange(status string, isListening bool) {
	mStatus.SetTitle(status)

	if isListening {
		mCopyAccessToken.Enable()
	}
}
