Ext.onReady(function(){

	Ext.QuickTips.init();

	// turn on validation errors beside the field globally
	Ext.form.Field.prototype.msgTarget = 'side';

	var bd = Ext.getBody();

	/*
	 * ================  Simple form  =======================
	 */
	bd.createChild({tag: 'h2', html: 'Register Form'});


	var register = new Ext.FormPanel({
		labelWidth: 75, // label settings here cascade unless overridden
		url:'/app/register.cgi',

		frame:true,
		title: 'Register Form',
		bodyStyle:'padding:5px 5px 0',
		width: 350,
		defaults: {width: 230},
		defaultType: 'textfield',

		items: [{
			fieldLabel: 'First Name',
			name: 'first',
			allowBlank:false
		    },{
			fieldLabel: 'Last Name',
			name: 'last',
			allowBlank:false
		    },{
			fieldLabel: 'Company',
			name: 'company',
			allowBlank:true
		    }, {
			fieldLabel: 'Email',
			name: 'email',
			vtype:'email',
			allowBlank:false 
		    }
		    ],

		buttons: [{
			text: 'Save',
			handler:function() {
			    register.getForm().submit({
				    method:'GET', 
				    waitTitle:'연결중입니다', 
				    waitMsg:'데이타 송신중...',
				    success:function() {
					Ext.Msg.alert('Status', '참가 신청 되었습니다!', function(btn, text){
						if (btn == 'ok'){
						    var redirect = 'index.html'; 
						    window.location = redirect;
						}
					    });
				    },
				    failure:function(form,action) {
					if(action.failureType == 'server'){ 
					    obj = Ext.util.JSON.decode(action.response.responseText); 
					    Ext.Msg.alert('Failed!', obj.errors.reason); 
					}else{ 
					    Ext.Msg.alert('Warning!', action.response.responseText); 
					} 
					login.getForm().reset(); 
				
				    }

				});
			}
		    },{
			text: 'Cancel'
		    }]
	    });

	register.render('register-form');
    });