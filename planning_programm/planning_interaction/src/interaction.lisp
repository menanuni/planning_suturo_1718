(in-package :planning-interaction)

;; Publisher for publishing calculated magnitude of wrench-force see @calculate-wrench-magnitude
(defvar *magnitude-publisher*)

;; Publisher for publishing a 15 when handshake is detected
(defvar *handshake-publisher*)

;; Actionclient for sound-play text-to-speak action
(defvar *sound-play-actionclient*)

;; Fluent for stating if handshake is detected or not
(defvar *handshake-detection* (cram-language:make-fluent))




;; say (message)
;;
;; Utilizes sound_play package to play phoenetic string 
;;  
;; @input   string message - the message to speak out loud 
;; @output  sound_play-msg:SoundRequestResult - information about played sound


(defun say (message)
  "Uses sound_play service to let the pr2 say a string out loud"
    (let
        ((actiongoal
      (actionlib:make-action-goal *sound-play-actionclient* sound_request 
        (roslisp:make-msg "sound_play/SoundRequest"
                          :sound -3
                          :command 1
                          :arg message
                          :arg2 ""))))
      (actionlib:call-goal *sound-play-actionclient* actiongoal)))




;; get-pointing-pose (pose)
;;
;; Points at a pose the pr2 cant reach. Uses static x-value to ensure that theres a kinematic solution
;; to Point at this position.
;;  
;; @input   geometry_msgs/PoseStamped pose  - unreachable Pose to Point at
;; @output  geometry_msgs/PoseStamped       - reachable Pose to Point at


(defun get-pointing-pose (pose)
  "Calculates pointing pose for given pose. Will be used to let the Pr2 use his Gripper to point at this pos"
  (let ((pose-in-baselink (planning-logic::transform-pose pose "base_link")))
                          (roslisp:modify-message-copy pose-in-baselink
                               (geometry_msgs-msg:x
                                geometry_msgs-msg:position
                                geometry_msgs-msg:pose) 2)))




;; ask-human-to-move-robot(pose label moving-command)
;;
;; Interacts with Human if Object is not reachable. Drives into Homeposition
;; Points at Object. Says String and then waits for Human to move Object and
;; shake his hand
;;
;; +++ UNDER CONSTRUCTION +++
;;  
;; @input   geometry_msgs/PoseStamped pose - pose of unreachable object
;; @input   string label                   - label of object as String (e.g. "Ja Milch")
;; @input   int moving-command             - 2 for left, 3 for right arm. Default is 3
;; @output  undefined


(defun ask-human-to-move-object (pose label &optional (moving-command 3))
  (planning-motion::call-motion-move-arm-homeposition)
  (let ((pose-to-point
          (get-pointing-pose pose)))
    (planning-motion::call-motion-move-arm-to-point pose-to-point "" moving-command)) 
  (say (concatenate 'string "I cannot grasp this object over there. Can you please move the " label  " and shake my Hand?")))




;; drive-to-human ()
;;
;; Drives into a safe position, where he is able to reach a human.
;; Position is near the wooden Table in the iai Kitchen.
;;
;;  
;; @output  undefined


(defun drive-to-human ()
  "Drives into a Position where pr2 is able to interact with Human"
  (say "Driving to my Human now")
  (planning-motion::call-motion-move-arm-homeposition 10)
  (planning-move::move-base-to-point -0.1566 -0.7442 0 -90)
  )




;; calculate-wrench-magnitude (msg)
;;
;; Calculates magnitude of the forcevectors given by the force-, and torque-sensors on the
;; Pr2's right gripper. It filles a fluent with nil and Publishes a 15 on the ... topic
;; when a Handshake is detected at the right gripper.
;;
;;
;; @input   geometry_msgs/WrenchStamped - The message containing the wrist sensory data with force and torque
;; @output  undefined


(defun calculate-wrench-magnitude (msg)
  (cram-language:sleep 0.01)
  (let ((magnitude (sqrt 
                   (+ 
                    (planning-logic::square (geometry_msgs-msg:x (geometry_msgs-msg:force (geometry_msgs-msg:wrench msg))))
                    (planning-logic::square (geometry_msgs-msg:y (geometry_msgs-msg:force (geometry_msgs-msg:wrench msg))))
                    (planning-logic::square (geometry_msgs-msg:z (geometry_msgs-msg:force (geometry_msgs-msg:wrench msg))))))))
    (when *magnitude-publisher*
      (roslisp:publish *magnitude-publisher*
                       (roslisp:make-msg
                        "std_msgs/Float32"
                        :data magnitude)))
    (if
     (>= magnitude 15)
     (progn
       (setf (cram-language:value *handshake-detection*) nil)
       (roslisp:publish *handshake-publisher* (roslisp:make-msg "std_msgs/Float32" :data 15)))
     (progn
           (setf (cram-language:value *handshake-detection*) T)
           (roslisp:publish *handshake-publisher* (roslisp:make-msg "std_msgs/Float32" :data 0)))
           )))




;; init-interaction()
;;
;; Initialization of all required components for this package.
;; Contains all publishers and subscribers. 
;;
;; 
;; @output  undefined


(defun init-interaction ()
  (setf *magnitude-publisher* (roslisp:advertise "/planning_interaction/wrench_force_magnitude" "std_msgs/Float32"))
  (setf *handshake-publisher* (roslisp:advertise "/planning_interaction/handshake_detection" "std_msgs/Float32"))
  (setf *sound-play-actionclient* (actionlib:make-action-client "/sound_play" "sound_play/SoundRequestAction"))
  (loop until (actionlib:wait-for-server *sound-play-actionclient* 5.0)
        do (roslisp:ros-info "init-interaction" "sound_play node has not been started correctly. Please use roslaunch sound_play soundplay_node.py"))
  (roslisp:ros-info "init-interaction" "Sound_play action initialized")
  (let ((zeroed-sub (roslisp:subscribe "/ft/l_gripper_motor_zeroed" "geometry_msgs/WrenchStamped" #'calculate-wrench-magnitude :max-queue-length 1)))
  (loop while (not
               (roslisp:msg-slot-value
                (roslisp:msg-slot-value zeroed-sub :subscription)
                :publisher-connections))
        do
           (roslisp:ros-info "init-interaction" "Topic /ft/l_gripper_motor_zeroed is empty. Please startup the robot_wrist_ft_tools package.")
           (sleep 5)
           ))
  (roslisp:ros-info "init-interaction" "Everything has been started correctly. Package is running, and ready to use.")
  (return-from init-interaction())
  )
