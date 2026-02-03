(defun c:dclloader()
  (setq dlg_file (getfiled "选择要预览的对话框所在文件" "E:\\code\\Projects\\Integrated-skid-mounted-house\\demo.dcl" "DCL" 2))
  (if (= dlg_file nil) (exit))
  (setq dlg_name (getstring "\n对话框名称:"))
  (if (= dlg_name "") (exit))
  (setq dlg_id (load_dialog dlg_file))
  (if (< dlg_id 0) (exit))
  (setq std 0)
  (if (not (new_dialog dlg_name dlg_id)) (exit))
  (action_tile "accept" "(done_dialog 1)")
  (action_tile "cancel" "(done_dialog 0)")
  (setq std (start_dialog))
  (unload_dialog dlg_id)
  (cond ((= std 1) (princ "确定"))
	((= std 0) (princ "取消"))
	)
  (princ)
)

(defun c:select_blueprint ()
  ;; 加载包含对话框定义的 DCL 文件（当前 repo 中的 demo.dcl）
  (setq dlg_file "E:\\code\\Projects\\Integrated-skid-mounted-house\\demo.dcl")
  (setq dlg_id (load_dialog dlg_file))
  (if (< dlg_id 0)
    (progn (princ "\n无法加载对话文件: ") (princ dlg_file) (princ) (exit))
  )

  ;; 打开 blueprint_type 对话框
  (if (not (new_dialog "blueprint_type" dlg_id))
    (progn (unload_dialog dlg_id) (princ "\n无法创建对话: blueprint_type") (exit))
  )
  ;; 设置单选按钮动作
  (action_tile "architectural" "(setq selected_type \"architectural\")")
  (action_tile "structural" "(setq selected_type \"structural\")")
  (action_tile "electrical" "(setq selected_type \"electrical\")")
  (action_tile "plumbing" "(setq selected_type \"plumbing\")")
  (action_tile "accept" "(done_dialog 1)")
  (action_tile "cancel" "(done_dialog 0)")

  (setq dlg_ret (start_dialog))

  ;; 如果用户按下确定，检查是否选择了建筑图纸
  (if (= dlg_ret 1)
    (progn
      (if (equal selected_type "architectural")
        (princ "\n已选择建筑图纸类型。")
        (princ (strcat "\n已选择图纸类型: " selected_type))
      )
      ;; 如果选择了建筑图纸，显示标题栏信息输入对话框
      (if (equal selected_type "architectural")
        (progn
          ;; 显示 title_table 对话框以输入标题栏信息
          (if (not (new_dialog "title_table" dlg_id))
            (princ "\n无法创建对话: title_table")
            (progn
              (action_tile "accept" "(done_dialog 1)")
              (action_tile "cancel" "(done_dialog 0)")
              (start_dialog)
            )
          )
        )
      )
    )
  )

  (unload_dialog dlg_id)
  (princ)
)