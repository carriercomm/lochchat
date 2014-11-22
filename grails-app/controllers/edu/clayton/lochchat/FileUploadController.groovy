package edu.clayton.lochchat

class FileUploadController {

    def download(String chatId, String fileId) {
      def chat = Chat.findByUniqueId(chatId)
      def fileUpload = FileUpload.findByIdAndChat(fileId, chat)
      if (fileUpload) {
        def file = new File(fileUpload.path)
        if (file.exists()) {
          response.setContentType("application/octet-stream")
          response.setHeader("Content-disposition", "attachment;filename=${fileUpload.filename}")
          response.outputStream << file.bytes
          response.outputStream.flush()
        }
        else response.sendError(404)
      }
    }
}
