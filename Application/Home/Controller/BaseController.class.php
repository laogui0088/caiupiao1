<?php
namespace Home\Controller;
use Think\Controller;

class BaseController extends Controller{
	
	public function _initialize(){
	    getConfigs();
		
		// 安全检查 - 防止SQL注入
		$this->checkSqlInjection();
		
		// 检测登录状态
		$userid = session('user');
		if (C('is_weixin') == '1' && is_weixin()) {
			if(CONTROLLER_NAME!='Index'){
				if(empty($userid['id'])){
					$this->redirect('Index/wxlogin');
				}
			}
		} else {
			if(CONTROLLER_NAME!='Index' && CONTROLLER_NAME!='Run'){
				if(empty($userid['id'])){
					$this->redirect('Home/Index/login');
				}
			}
		}
		
		if (isset($userid['id'])) {
			// 修复SQL注入漏洞
			$userinfo = M('user')->where(array('id' => intval($userid['id'])))->find();
			if (!$userinfo) {
				session(null);
				$this->redirect('Home/Index/index');
			}
		} else {
			$userinfo = array();
		}
		$this->assign('userinfo',$userinfo);
		$this->assign('version',VERSION);
	}
	
	/**
	 * 基础安全检查
	 */
	protected function checkSqlInjection(){
		// 检查常见的SQL注入攻击
		$dangerous = array('union', 'select', 'insert', 'update', 'delete', 'drop', 'create', 'alter');
		foreach($_REQUEST as $key => $val){
			if(is_string($val)){
				$val = strtolower($val);
				foreach($dangerous as $word){
					if(strpos($val, $word) !== false){
						$this->error('非法请求');
					}
				}
			}
		}
	}
}
?>