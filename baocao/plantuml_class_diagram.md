# MÃ NGUỒN PLANTUML BIỂU ĐỒ PHÂN LỚP (HÌNH 2.17)
*(Định dạng: Đen trắng 100%, nét vẽ vuông góc không xiên xéo, bao quát toàn bộ 10 Collection Firebase)*
*(Cách dùng: Vào draw.io -> Arrange -> Insert -> Advanced -> PlantUML -> Dán mã vào)*

```plantuml
@startuml
' === THIẾT LẬP GIAO DIỆN ĐEN TRẮNG CHUẨN ĐỒ ÁN BÁO CÁO ===
skinparam linetype ortho
skinparam monochrome true
skinparam shadowing false
skinparam defaultFontName Arial
skinparam defaultFontSize 11
skinparam classAttributeIconSize 0
skinparam roundcorner 0
skinparam nodesep 50
skinparam ranksep 60

' Màu sắc đen trắng thuần túy cho toàn bộ các phần tử
skinparam class {
    BackgroundColor white
    BorderColor black
    ArrowColor black
}
skinparam package {
    BackgroundColor white
    BorderColor black
}

' ================= TẦNG 1: NGƯỜI DÙNG & TƯƠNG TÁC (USERS, CHATSESSIONS) =================
package "Tầng Người dùng & Tương tác" {
    class Users {
      - uid: String
      - displayName: String
      - email: String
      - photoUrl: String
      - phoneNumber: String
      - role: String
      - isActive: Boolean
      - createdAt: Timestamp
      + register()
      + login()
    }

    class ChatSessions {
      - sessionId: String
      - userId: String
      - title: String
      - messages: Array
      - createdAt: Timestamp
      - updatedAt: Timestamp
      + createSession()
      + appendMessage()
    }
}

' ================= TẦNG 2: NGHIỆP VỤ VƯỜN & GIAO DỊCH (SCAN, GARDEN, DIARY, ORDERS) =================
package "Tầng Nghiệp vụ Vườn & Giao dịch" {
    class ScanHistory {
      - scanId: String
      - userId: String
      - type: String
      - prediction: String
      - predictionVi: String
      - confidence: Double
      - modelUsed: String
      - imageUrl: String
      - timestamp: Timestamp
      + saveScanRecord()
    }

    class MyGarden {
      - id: String
      - userId: String
      - scientificName: String
      - nickname: String
      - zone: String
      - waterFrequencyDays: Integer
      - lastWatered: Timestamp
      - nextWatering: Timestamp
      - healthStatus: String
      + confirmWatered()
      + updateZone()
    }

    class DiaryNotes {
      - noteId: String
      - plantId: String
      - title: String
      - note: String
      - imageUrl: String
      - heightCm: Double
      - timestamp: Timestamp
      + addEntry()
      + deleteEntry()
    }

    class Orders {
      - orderId: String
      - userId: String
      - items: Array
      - totalPrice: Integer
      - paymentMethod: String
      - paymentStatus: String
      - status: String
      - shippingAddress: String
      - createdAt: Timestamp
      + createOrder()
      + updateStatus()
    }
}

' ================= TẦNG 3: TRI THỨC, KHO HÀNG & NỘI DUNG (PLANTS, DISEASES, PRODUCTS, HANDBOOK) =================
package "Tầng Cơ sở tri thức, Kho hàng & Nội dung" {
    class plants_info {
      - scientificName: String
      - name_vi: String
      - family: String
      - light_requirement: String
      - watering_interval_days: Integer
      - optimal_humidity: String
      - optimal_temperature: String
      - image_url: String
      + getPlantDetails()
    }

    class DiseasesInfo {
      - id: String
      - nameVi: String
      - nameEn: String
      - severity: String
      - pathogen: String
      - symptoms: String
      - culturalControls: Array
      - biologicalTreatments: Array
      + getDiseaseDetails()
    }

    class ShopProducts {
      - id: String
      - name: String
      - category: String
      - price: Integer
      - stock: Integer
      - visible: Boolean
      + checkStock()
      + updateStock()
    }

    class PlantHandbook {
      - id: String
      - title: String
      - summary: String
      - content: String
      - imageUrl: String
      - published: Boolean
      - author: String
      + publishArticle()
    }
}

' === CÁC ĐƯỜNG NỐI VUÔNG GÓC (ORTHO) GIỮA CÁC COLLECTION ===
Users "1" -down-> "0..*" ChatSessions : chats
Users "1" -down-> "0..*" ScanHistory : performs
Users "1" -down-> "0..*" MyGarden : owns
Users "1" -down-> "0..*" Orders : places

MyGarden "1" *-right-> "0..*" DiaryNotes : contains
MyGarden "0..*" -down-> "1" plants_info : references

ScanHistory "0..*" -down-> "1" plants_info : identifies
ScanHistory "0..*" -down-> "1" DiseasesInfo : diagnoses

Orders "0..*" -down-> "1..*" ShopProducts : includes

' === KHÓA BỐ CỤC ĐỂ ĐƯỜNG DÂY ĐI THẲNG TẮP KHÔNG GIAO CẮT ===
ChatSessions -[hidden]right-> ScanHistory
ScanHistory -[hidden]right-> MyGarden
MyGarden -[hidden]right-> Orders

DiseasesInfo -[hidden]right-> plants_info
plants_info -[hidden]right-> ShopProducts
ShopProducts -[hidden]right-> PlantHandbook

@enduml
```
