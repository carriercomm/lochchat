databaseChangeLog = {

	include file: '201411111458-create-chat-class.groovy'

	include file: '201411171304-create-log-class.groovy'

	include file: '201411180901-create-message-class.groovy'

	include file: '201411211415-create-fileupload-class.groovy'

	include file: '201411211421-associate-chat-with-fileupload.groovy'

	include file: '201411211448-add-unique-id-to-fileupload.groovy'
}
