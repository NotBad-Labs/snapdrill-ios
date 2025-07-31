import SwiftUI

// MARK: - WelcomeHeader
// 位置: Presentation/Features/Dashboard/Components/WelcomeHeader.swift

/// 欢迎头部组件
/// 单一职责：显示用户欢迎信息和天气信息
/// 符合企业级开发标准：可复用、可测试、可维护
struct WelcomeHeader: View {
    
    // MARK: - Properties
    
    /// 用户信息
    let userInfo: BasicUserInfo?
    
    /// 天气信息（可选）
    let weatherInfo: WeatherInfo?
    
    /// 点击天气区域的回调
    let onWeatherTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        userInfo: BasicUserInfo?,
        weatherInfo: WeatherInfo? = nil,
        onWeatherTap: (() -> Void)? = nil
    ) {
        self.userInfo = userInfo
        self.weatherInfo = weatherInfo
        self.onWeatherTap = onWeatherTap
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 用户欢迎信息
            userGreetingSection
            
            Spacer()
            
            // 天气信息区域
            weatherSection
        }
        .padding(20)
        .background(gradientBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Private Views
    
    /// 用户问候区域
    private var userGreetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let userInfo = userInfo {
                Text("\(userInfo.greeting)，\(userInfo.username)！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("今天是学习的好日子，继续加油吧 🌟")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            } else {
                Text("欢迎回来！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("开始今天的学习吧")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    /// 天气信息区域
    private var weatherSection: some View {
        Group {
            if let weather = weatherInfo {
                Button(action: {
                    onWeatherTap?()
                }) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("今日天气")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 4) {
                            Text(weather.condition.emoji)
                                .font(.title3)
                            
                            Text("\(weather.temperature)°C")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // 占位区域
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.2))
                    .frame(width: 60, height: 40)
                    .overlay(
                        Image(systemName: "cloud")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
        }
    }
    
    /// 渐变背景
    private var gradientBackground: some View {
        LinearGradient(
            colors: [
                Color.blue,
                Color.purple
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Supporting Data Models
// TODO: 架构重构 - 将这些模型迁移到Domain层

/// 天气信息模型
struct WeatherInfo {
    let temperature: Int
    let condition: WeatherCondition
    let location: String
    
    enum WeatherCondition {
        case sunny
        case cloudy
        case rainy
        case snowy
        
        var emoji: String {
            switch self {
            case .sunny: return "☀️"
            case .cloudy: return "☁️"
            case .rainy: return "🌧️"
            case .snowy: return "❄️"
            }
        }
        
        var description: String {
            switch self {
            case .sunny: return "晴天"
            case .cloudy: return "多云"
            case .rainy: return "雨天"
            case .snowy: return "雪天"
            }
        }
    }
    
    static let mockData = WeatherInfo(
        temperature: 23,
        condition: .sunny,
        location: "北京"
    )
}

// MARK: - Preview

#if DEBUG
struct WelcomeHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 有用户信息和天气信息
            WelcomeHeader(
                userInfo: BasicUserInfo.mockData,
                weatherInfo: WeatherInfo.mockData,
                onWeatherTap: {
                    print("天气区域被点击")
                }
            )
            
            // 只有用户信息
            WelcomeHeader(
                userInfo: BasicUserInfo.mockData,
                weatherInfo: nil
            )
            
            // 无用户信息
            WelcomeHeader(
                userInfo: nil,
                weatherInfo: WeatherInfo.mockData
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif