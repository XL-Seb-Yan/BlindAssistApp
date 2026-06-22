import Foundation

enum AssistantStatus: String {
  case idle = "未开始"
  case ready = "准备拍照"
  case analyzing = "正在分析"
  case completed = "分析完成"
  case paused = "已暂停"
}
