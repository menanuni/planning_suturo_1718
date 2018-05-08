(in-package :planning-old)

(defvar *pose-array* nil)
(defvar *my-array* (make-array '(10) 
                                 :initial-contents
                                 '("features1" "features2" "features3" "features4" "features5" "features6" "features7" "features8" "features9" "features10")))

(defvar *pose* nil)


;;NICHT MEHR AKTUELL ENTSCHEIDET MOTION SELBER
;; (defun ask-Knowledge-For-Poke-Point(point-center-of-object)
;;   "Calling knowledge-service to look for a point to poke for specific object"
;;   (cpl:with-retry-counters ((retry-counter 10))
;;     (cpl:with-failure-handling
;;         ((cpl:simple-plan-failure (error-object)
;;            (format t "An error happened: ~a~%" error-object)
;;            (cpl:do-retry retry-counter
;;              (format t "Now retrying~%")
;;              (roslisp:ros-info "Knowledge" "Now retrying")
;;              (cpl:retry))
;;            (format t "Reached maximum amount of retries. Now propagating the failure up.~%")
;;            (roslisp:ros-error "Knowledge" "Reached maximum amount of retries. Now propagating the failure up.")))    
;;       (roslisp:with-fields (object) point-center-of-object
;;         (setf point-center-of-object
;;               (roslisp:call-service "/poke_position_service/calculate_poke_position" 'object_detection-srv:PokeObject :detection object))
;;         (roslisp:with-fields (error_message) point-center-of-object
;;           (if (or (string= error_message "Failed to call service 'calculate_poke_position'. Transformation failed!")
;;                   (string= error_message "Failed to call service 'calculate_poke_position'. Prolog found no solution!"))
;;               (progn
;;                 (roslisp:ros-warn "Knowledge" "Service call failed.")
;;                 (cpl:fail 'planning-error::knowledge-error :message (format nil "knowledge service failed with: ~a" error_message)))
;;               (print point-center-of-object)))))))  





;NICHT MEHR AKTUELL!    
;; (defun call-Vision-Point ()
;;   "Call vision service, to look for point. Returns ObjectDetection object"
;;   (cpl:with-retry-counters ((retry-counter 10))
;;     (cpl:with-failure-handling
;;         ((cpl:simple-plan-failure (error-object)
;;            (format t "An error happened: ~a~%" error-object)
;;            (cpl:do-retry retry-counter
;;              (format t "Now retrying~%")
;;              (cpl:retry))
;;            (format t "Reached maximum amount of retries. Now propagating the failure up.~%")))
;;       (let ((response
;;               (roslisp:call-service
;;                "/vision_main/objectPoint"
;;                'object_detection-srv:visobjectinfo)))
;;         ;;Debug to find NaN message from vision
;;         (setf not-a-number response)
;;         (print not-a-number)
;;         (roslisp:with-fields ((x (geometry_msgs-msg:x geometry_msgs-msg:point)) 
;;                               (y (geometry_msgs-msg:y geometry_msgs-msg:point))
;;                               (z (geometry_msgs-msg:z geometry_msgs-msg:point)))
;;             (object_detection-msg:position (object_detection-srv:object response))
;;           ;;If Vision returns a NaN and it is of type String this will recover from the error
;;           (if (or (stringp x)
;;                   (stringp y)
;;                   (stringp z))
;;               (cpl:fail 'planning-error::vision-error :message "One or more of the coordinates returned by the service /vision_main/objectPoint is of type String
;;                         which is likely the not a number error")
;;               (if (or (sb-ext:float-nan-p x)
;;                       (sb-ext:float-nan-p y)
;;                       (sb-ext:float-nan-p z))
;;                   (cpl:fail 'planning-error::vision-error :message "One or more of the coordinates returned by the service /vision_main/objectPoint is not a number")
;;                   (roslisp:with-fields (object_detection-msg:error) (object_detection-srv:object response)
;;                     (if (or (string= "Cloud empty. " object_detection-msg:error)
;;                             (string= "Cloud was empty after filtering. " object_detection-msg:error)
;;                             (string= "No plane found. " object_detection-msg:error)
;;                             (string= "Final extracted cluster was empty. " object_detection-msg:error))
;;                         (cpl:fail 'planning-error::vision-error :message object_detection-msg:error)
;;                         (progn
;;                           (format t "service call successful")
;;                           (return-from call-vision-point
;;                             (roslisp:call-service "/vision_main/objectPoint" 'object_detection-srv:VisObjectInfo))))))))))))



;Hier müsste die logik noch einmal angepasst werden
(defun check-Points-Is-Equal (msg-one msg-two delta)
  "Compares two points with delta."
  (roslisp::ros-info "check-points-is-equal" "Starting to check if point of object is still valid")
  (roslisp:with-fields ((x1 (geometry_msgs-msg:x geometry_msgs-msg:point)) 
                        (y1 (geometry_msgs-msg:y geometry_msgs-msg:point))
                        (z1 (geometry_msgs-msg:z geometry_msgs-msg:point)))
      (object_detection-msg:position (object_detection-srv:object msg-one))
     (roslisp:with-fields ((x2 (geometry_msgs-msg:x geometry_msgs-msg:point)) 
                           (y2 (geometry_msgs-msg:y geometry_msgs-msg:point))
                           (z2 (geometry_msgs-msg:z geometry_msgs-msg:point)))
                        (object_detection-msg:position (object_detection-srv:object msg-two))
       (let (
             (dx (abs (- x1 x2)))
             (dy (abs (- y1 y2)))
             (dz (abs (- z1 z2))))
         (if (and
              (<= dx delta)
              (<= dy delta)
              (<= dz delta))
             (print t)
             (print nil))))))



;;fliegt raus sobald motion auf pose stamped ist.
(defun disassemble-Pose-Msg-To-Point-Stamped (pose-array amount)
  "making pose_stamped to point_stamped"
  (roslisp:with-fields
      ((header1
        (geometry_msgs-msg:header))
       (point1
        (geometry_msgs-msg:position
         geometry_msgs-msg:pose)))
      (aref pose-array amount)
    (return-from disassemble-Pose-Msg-To-Point-Stamped (roslisp:make-msg "geometry_msgs/pointstamped" (header) header1 (point) point1))))




;; (defun move-Base-To-Point-Safe (x y z angle &optional (motion 1))
;;   (cram-language:wait-for
;;    (move-Base-To-Point 0.15 0.5 0 -90 motion))
;;   (if
;;    (and
;;     (> angle 90)
;;     (< angle 270))
;;    (move-Base-To-Point -0.29 1 0 180 motion)
;;    (move-Base-To-Point 0.75 0.8 0 0 motion)))





;; ;; fiegt raus, wenn Vision weiter ist
;; ;; Beschreibung: Extrahiert alle Informationen aus der
;; ;; Visioncloud und speichert normal_features, color_features,
;; ;; object_amount und object_pose auf dem Parameterserver.

;; ;; @param: visionclouds
;; ;; @return: object_pose
;; (defun disassemble-Vision-Call (visionclouds)
;;   "dissamble the whole vision-msg, setting new params onto param server"
;;   (roslisp:with-fields
;;       ((normal_features
;;         (vision_suturo_msgs-msg:normal_features))
;;        (color_features
;;         (vision_suturo_msgs-msg:color_features))
;;        (object_amount
;;         (vision_suturo_msgs-msg:object_amount))
;;        (object_poses
;;         (vision_suturo_msgs-msg:object_information)))
;;       (vision_suturo_msgs-srv:clouds visionclouds)
;;     (roslisp:set-param "normal_features" normal_features)
;;     (roslisp:ros-info (disassemble-Vision-Call)
;;                       "param normal_features now exist")
;;     (roslisp:set-param "color_features" color_features)
;;     (roslisp:ros-info (disassemble-Vision-Call)
;;                       "param color_features now exist")    
;;     (roslisp:set-param "object_amount" object_amount)
;;     (roslisp:ros-info (disassemble-Vision-Call)
;;                       "param object_amount now exist")
;;     (setf *pose* object_poses))
;;   (let ((n (roslisp:get-param "object_amount")))
;;     (if (> n 0)
;;         (loop for amount from 1 to n do
;;           (if (= amount 1)
;;               (set-Params-Features 0 0 308 24 amount)
;;               (set-Params-Features
;;                (* (- amount 1) 308)
;;                (* (- amount 1) 24)
;;                (* amount 308)
;;                (* amount 24)amount)))))
;;   (Return-from disassemble-vision-call *pose*))

;; (defun list-to-1d-array (list)
;;   "convert list to array"
;;   (make-array (length list)
;;               :initial-contents list))


;; ;; Beschreibung: Eine Hilfsfunktion für die Funktion disassemble-Vision-Call,
;; ;; um aus normal_features und color_features konkateniert ein features-X zu
;; ;; erstellen. (Knowledge ben ̈otigt ein Array in dem zuerst color_features
;; ;; vorkommen und direkt im Anschluss normal_features)

;; ;; @param: normal-s color-s normal-e color-e amount
;; ;; @return: Nil
;; (defun set-Params-Features (normal-s color-s normal-e color-e amount)
;;   "soon"
;;   (roslisp:set-param (concatenate 'string "normal_features"
;;                                   (write-to-string amount))
;;                      (subseq (roslisp:get-param "normal_features") normal-s normal-e))
;;   (roslisp:set-param (concatenate 'string "color_features"
;;                                   (write-to-string amount))
;;                      (subseq (roslisp:get-param "color_features") color-s color-e))
;;   (roslisp:set-param (concatenate 'string "features"
;;                                   (write-to-string amount))
;;                      (append
;;                       (roslisp:get-param (concatenate 'string "color_features"
;;                                                       (write-to-string amount)))
;;                       (roslisp:get-param (concatenate 'string "normal_features"
;;                                                       (write-to-string amount)))))(print "made it"))


      

;; (defun find-Object (x z)
;;   "Looking around to find /beliefstate/gripper_empty an object, restarting at current Point if reused" 
;;   (block find-Object-Start
;;     (loop for i from *beliefstateHead* to 24 do
;;       (let ((c (mod i 12)))
;;         (progn
;;           (planning-move::move-Head x(second (assoc c *headMovementList*)) z)
;;           (setf *beliefstateHead* c)
;;           (setf *pose-array*
;;                (planning-logic::disassemble-vision-call
;;                 (planning-vision::call-vision-object-clouds)))
;;           (if (> (roslisp:get-param "object_amount") 0)
;;               (return-from find-Object-Start)))))
;;     (roslisp::ros-info "find-Object" "Couldnt find any Object in front of me")
;;     (return-from find-Object nil))
;;   (roslisp::ros-info "find-Object" "I see the Object. Head is in Position")
;;   (return-from find-Object T))
