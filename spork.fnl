;; used for debugging
(local view (require :fennelview))
(global pp (fn [x] (print (view x))))

(local lume (require "lume"))


;; notification wrapper

(fn notify
  [subtitle info-text]
  (let [notification (hs.notify.new {:title :Hammerspoon
                                     :subTitle subtitle
                                     :informativeText info-text})]
    (: notification :send notification)))


;; menu bar clock
;;;;;;;;;;;;;;;;;;

(lambda tz-offset
  [offset]
  (os.date "%H:%M" (+ (os.time) (* offset 60 60))))

(lambda menu-bar-clock
  [menu-options]
  (let [menu-bar (hs.menubar.new)
        menu (fn []
               (: menu-bar :setMenu (fn [] menu-options)))
        clock (fn []
                (menu)
                (: menu-bar :setTitle (os.date "UTC %H:%M")))
        run-every-second (partial hs.timer.doEvery 1)]
    (run-every-second clock)))

(menu-bar-clock [{:title (string.format "%s %10s" "Amsterdam " (tz-offset 1))}
                 {:title (string.format "%s %15s" "Belgrade" (tz-offset 1))}
                 {:title "-"}
                 {:title (string.format "%s %22s" "Sofia" (tz-offset 2))}
                 {:title "-"}
                 {:title (string.format "%s %21s" "Dubai" (tz-offset 4))}
                 {:title "-"}
                 {:title (string.format "%s %8s" "Kuala Lumpur" (tz-offset 8))}])

;; quick app switching

(lambda get-app [modifiers key app]
  (hs.hotkey.bind modifiers key (fn []
                                  (hs.application.launchOrFocus app))))

(get-app [:ctrl] "7" "Slack")
(get-app [:ctrl] "8" "Emacs")
(get-app [:ctrl] "9" "Firefox")

;; (fn tell [something name]
;;   (.. "tell " something " \"" name "\"" " end tell"))


(fn clear-all-notifications
  ;; Remove all notifications, from every app
  []
  (hs.osascript.applescript "tell application \"System Events\"
                               tell process \"NotificationCenter\"
                                   set numwins to (count windows)
                                   repeat with i from numwins to 1 by -1
                                       click button \"Close\" of window i
                                   end repeat
                               end tell
                             end tell"))


(hs.hotkey.bind [:cmd :alt] "8" (fn [] (clear-all-notifications)))



;; window actions

(lambda move-window [win positions]
  (let [frame (: win :frame)
        _ (each [key value (pairs positions)]
            (tset frame key value))]
    (: win :setFrame frame)))

(lambda get-window []
  (let [win (hs.window.focusedWindow)
        max (-> win
                (: :screen)
                (: :frame))]
    (values win max)))


;; +-----------------+
;; |        |        |
;; |        |  HERE  |
;; |        |        |
;; +-----------------+
;;
;; a nod to https://github.com/jasonrudolph
;; for the ASCII art diagrams

(lambda move-right []
  (let [(win max) (get-window)]
    (move-window win {:x (+ max.x (/ max.w 2))
                      :y max.y
                      :w (/ max.w 2)
                      :h max.h})))

(hs.hotkey.bind [:cmd :alt] "l" (fn [] (move-right)))

;; +-----------------+
;; |        |        |
;; |  HERE  |        |
;; |        |        |
;; +-----------------+

(lambda move-left []
  (let [(win max) (get-window)]
    (move-window win {:x max.x
                      :y max.y
                      :w (/ max.w 2)
                      :h max.h})))

(hs.hotkey.bind [:cmd :alt] "h" (fn [] (move-left)))

;; +------------------+
;; |                  |
;; |   WHOLE SCREEN   |
;; |                  |
;; +------------------+


(lambda maximise []
  (let [(win max) (get-window)]
    (move-window win {:x max.x
                      :y max.y
                      :w max.w
                      :h max.h})))

(hs.hotkey.bind [:cmd :alt] "m" (fn [] (maximise)))

;; +----------------+
;; |   |        |   |
;; |   |  HERE  |   |
;; |   |        |   |
;; +----------------+

(lambda center []
  (let [(win max) (get-window)]
    (move-window win {:x (+ max.x (/ max.w 5))
                      :y max.y
                      :w (* max.w (/ 3 5))
                      :h max.h})))

(hs.hotkey.bind [:cmd :alt] "." (fn [] (center)))

;; +----------------+
;; |      HERE      |
;; |----------------|
;; |                |
;; +----------------+

(lambda top []
  (let [(win max) (get-window)]
    (move-window win {:x max.x
                      :y max.y
                      :w max.w
                      :h (/ max.h 2)})))

(hs.hotkey.bind [:cmd :alt] "k" (fn [] (top)))


;; +----------------+
;; |                |
;; |----------------|
;; |      HERE      |
;; +----------------+

(lambda bottom []
  (let [(win max) (get-window)]
    (move-window win {:x max.x
                      :y (+ max.y (/ max.h 2))
                      :w max.w
                      :h (/ max.h 2)})))

(hs.hotkey.bind [:cmd :alt] "j" (fn [] (bottom)))


(lambda play-sound [sound-name]
  (doto (hs.sound.getByName sound-name)
    (: :play)))

;; hs.application.get("Hammerspoon"):selectMenuItem("Console...")
;;  hs.application.launchOrFocus("Hammerspoon")

(lambda send-to-console [command]
  (let [name "Hammerspoon"]
    (doto (hs.application.get name)
      (: :selectMenuItem "Console..."))
    (hs.application.launchOrFocus name)
    (hs.eventtap.keyStrokes (.. command "\n"))))

;; (send-to-console "hs.console.clearConsole()")

;;(send-to-console "\"this \" .. \"that\"")
;;(send-to-console "print(\"this is nice!\")")

;; (lambda send-to-console2 []
;;   (let [name "Hammerspoon"]
;;     (hs.application.launchOrFocus name)
;;     (doto (hs.application.get name)
;;       (: :selectMenuItem "Console..."))
;;     ;; (doto (hs.application.get "Hammerspoon Console")
;;     ;;   (: :getMenuItems))
;;     (: (hs.application.get "Hammerspoon Console") :getMenuItems)
;;     ))

;; (send-to-console2)

;; (fn console-content []
;;   (let [content (hs.console.getConsole)]
;;     (hs.alert.show content nil nil 10)))

;; (console-content)

;; (play-sound "Tink")


(fn refresh
  ;; Sometimes the menubar tasks stay stuck after a full battery
  ;; drain.  This is a workaround to wake it up, when the battery
  ;; starts to be charged and the macbook's lid is opened again.
  [event-type]
  (when (= event-type hs.caffeinate.watcher.systemDidWake)
    (hs.reload)))

(local refresh-task (doto (hs.caffeinate.watcher.new refresh)
                      (: :start)))


;;(notify "Fennel config", "successfully loaded!")
