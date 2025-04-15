//
//  CustomDragger.swift
//  HotCha
//
//  Created by Yeji Seo on 4/11/25.
//

import SwiftUI
import UIKit


// MARK: - 드래그 가능한 UIKit 테이블 뷰 (UIKit 부분)
class DraggableBusStopTableViewController: UITableViewController {
    var busStops: [BusStop] = []
    var onArrivalStationChanged: ((Int) -> Void)? // 선택된 도착 정류장 콜백
    var onAlarmStationChanged: ((Int) -> Void)? // 선택된 알람 정류장 콜백
    var isDraggingDestination: Bool = true // 목적지 정류장을 드래그하는지 여부
    
    private var backgroundView: UIView?
    private var sourceIndexPath: IndexPath?
    
    // 목적지 정류장 인덱스를 찾는 함수
    private func getDestinationIndex() -> Int? {
        return busStops.firstIndex(where: { $0.arrivalStation })
    }
    
    // 알람 정류장 인덱스를 찾는 함수
    private func getAlarmIndex() -> Int? {
        return busStops.firstIndex(where: { $0.alarmStation })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 테이블 뷰 설정
        tableView.register(BusStopCell.self, forCellReuseIdentifier: "BusStopCell")
        tableView.backgroundColor = UIColor(Color.gray900)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 80, left: 0, bottom: 265, right: 0)
        
        // 드래그 제스처 설정
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        tableView.addGestureRecognizer(longPress)
    }
    
    // MARK: 테이블 뷰 데이터 소스
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return busStops.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BusStopCell", for: indexPath) as! BusStopCell
        
        // 현재 버스 정류장 데이터
        let busStop = busStops[indexPath.row]
        
        // SwiftUI 뷰 설정
        cell.configure(with: busStop)
        
        return cell
    }
    
    // MARK: 테이블 뷰 델리게이트
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if isDraggingDestination {
            updateArrivalStation(at: indexPath.row)
        } else {
            updateAlarmStation(at: indexPath.row)
        }
    }
    
    // MARK: 도착 정류장 업데이트
    func updateArrivalStation(at index: Int) {
        // 모든 정류장 선택 해제
        for i in 0..<busStops.count {
            busStops[i].arrivalStation = false
        }
        
        // 선택된 정류장만 선택
        busStops[index].arrivalStation = true
        
        // 알람 정류장이 목적지 정류장 이후에 있다면 조정
        if let alarmIndex = getAlarmIndex(), alarmIndex >= index {
            // 알람 정류장을 목적지 이전으로 이동 (최소 2정류장 전, 없으면 가장 가까운 정류장)
            updateAlarmStation(at: max(0, index - 2))
        }
        
        // 테이블 뷰 갱신
        tableView.reloadData()
        
        // 콜백 호출
        onArrivalStationChanged?(index)
    }
    
    // MARK: 알람 정류장 업데이트
    func updateAlarmStation(at index: Int) {
        // 목적지 정류장 인덱스 확인
        guard let destIndex = getDestinationIndex() else { return }
        
        // 알람 정류장은 목적지 정류장 이전에만 위치 가능
        let validIndex = min(destIndex - 1, index)
        
        // 인덱스 범위 확인 (0보다 작을 수 없음)
        let finalIndex = max(0, validIndex)
        
        // 모든 정류장 알람 상태 초기화
        for i in 0..<busStops.count {
            busStops[i].alarmStation = false
        }
        
        // 선택된 정류장 알람 설정
        busStops[finalIndex].alarmStation = true
        
        // 테이블 뷰 갱신
        tableView.reloadData()
        
        // 콜백 호출
        onAlarmStationChanged?(finalIndex)
    }
    
    // MARK: 롱 프레스 제스처 처리
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: tableView)
        
        switch gestureRecognizer.state {
        case .began:
            if let indexPath = tableView.indexPathForRow(at: location) {
                sourceIndexPath = indexPath
                
                // 목적지 정류장 드래그 모드인 경우
                if isDraggingDestination {
                    // 선택된 셀
                    guard let cell = tableView.cellForRow(at: indexPath) else { return }
                    
                    // 배경색 스냅샷 생성
                    let highlightView = UIView(frame: cell.frame)
                    highlightView.backgroundColor = UIColor(Color.purpleOpacity10)
                    
                    // 배경 뷰 테이블뷰에 추가
                    tableView.insertSubview(highlightView, belowSubview: cell)
                    backgroundView = highlightView
                    
                    // 도착 정류장 업데이트
                    updateArrivalStation(at: indexPath.row)
                }
                // 알람 정류장 드래그 모드인 경우
                else {
                    // 목적지 정류장 확인
                    guard let destIndex = getDestinationIndex() else { return }
                    
                    // 현재 위치가 목적지 정류장보다 앞에 있는지 확인
                    if indexPath.row < destIndex {
                        // 선택된 셀
                        guard let cell = tableView.cellForRow(at: indexPath) else { return }
                        
                        // 배경색 스냅샷 생성 (알람은 다른 색상 사용)
                        let highlightView = UIView(frame: cell.frame)
                        highlightView.backgroundColor = UIColor(Color.purpleOpacity10) // 알람용 색상 조정 가능
                        
                        // 배경 뷰 테이블뷰에 추가
                        tableView.insertSubview(highlightView, belowSubview: cell)
                        backgroundView = highlightView
                        
                        // 알람 정류장 업데이트
                        updateAlarmStation(at: indexPath.row)
                    }
                }
            }
            
        case .changed:
            guard let backgroundView = backgroundView, let sourceIndexPath = sourceIndexPath else { return }
            
            // 배경 뷰를 터치 위치에 맞게 이동
            var frame = backgroundView.frame
            frame.origin.y = location.y - frame.size.height / 2
            
            // 화면 범위 내에 유지
            if !busStops.isEmpty {
                let minY = tableView.rectForRow(at: IndexPath(row: 0, section: 0)).minY
                let maxY = tableView.rectForRow(at: IndexPath(row: busStops.count - 1, section: 0)).maxY - frame.size.height
                
                frame.origin.y = max(minY, min(maxY, frame.origin.y))
            }
            backgroundView.frame = frame
            
            // 현재 위치에 해당하는 인덱스 찾기
            if let newIndexPath = tableView.indexPathForRow(at: location), newIndexPath != sourceIndexPath {
                // 목적지 정류장 드래그 모드인 경우
                if isDraggingDestination {
                    // 도착 정류장 업데이트
                    updateArrivalStation(at: newIndexPath.row)
                }
                // 알람 정류장 드래그 모드인 경우
                else {
                    // 목적지 정류장 확인
                    guard let destIndex = getDestinationIndex() else { return }
                    
                    // 목적지 정류장보다 앞에 있는 경우에만 업데이트
                    if newIndexPath.row < destIndex {
                        updateAlarmStation(at: newIndexPath.row)
                    }
                }
                
                // 소스 인덱스 경로 업데이트
                self.sourceIndexPath = newIndexPath
            }
            
        case .ended, .cancelled:
            guard let backgroundView = backgroundView else { return }
            
            // 배경 뷰 제거
            UIView.animate(withDuration: 0.2, animations: {
                backgroundView.alpha = 0
            }) { _ in
                backgroundView.removeFromSuperview()
                self.backgroundView = nil
                self.sourceIndexPath = nil
            }
            
        default:
            break
        }
    }
}

// MARK: - 버스 정류장 셀 (UIKit)
class BusStopCell: UITableViewCell {
    private var hostingController: UIHostingController<AnyView>?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with busStop: BusStop) {
        // 기존 호스팅 컨트롤러 제거
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        
        // 새 호스팅 컨트롤러 생성
        let busStopView = BusStopElement(stopCase: busStop.busStopCase, busStop: busStop)
        let view = AnyView(
            ZStack(alignment: .bottom) {
                Divider()
                    .background(Color.gray100.opacity(0.15))
                busStopView
            }
            .background(
                Group {
                    if busStop.arrivalStation {
                        Color.purpleOpacity10
                    } else if busStop.alarmStation {
                        Color.purpleOpacity10 // 알람용 색상 조정 가능
                    } else {
                        Color.clear
                    }
                }
            )
        )
        
        hostingController = UIHostingController(rootView: view)
        hostingController?.view.backgroundColor = .clear
        
        if let hostingView = hostingController?.view {
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(hostingView)
            
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ])
        }
        
        // 배경색 설정
        if busStop.arrivalStation {
            backgroundColor = UIColor(Color.purpleOpacity10)
        } else if busStop.alarmStation {
            backgroundColor = UIColor(Color.purpleOpacity10) // 알람용 색상 조정 가능
        } else {
            backgroundColor = .clear
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundColor = .clear
    }
}

// MARK: - SwiftUI를 위한 UIViewControllerRepresentable
struct DraggableBusStopList: UIViewControllerRepresentable {
    var busStops: [BusStop]
    var onArrivalStationChanged: (Int) -> Void
    var onAlarmStationChanged: (Int) -> Void
    var isDraggingDestination: Bool // 목적지 정류장을 드래그하는지 여부
    
    func makeUIViewController(context: Context) -> DraggableBusStopTableViewController {
        let controller = DraggableBusStopTableViewController(style: .plain)
        controller.busStops = busStops
        controller.onArrivalStationChanged = onArrivalStationChanged
        controller.onAlarmStationChanged = onAlarmStationChanged
        controller.isDraggingDestination = isDraggingDestination
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DraggableBusStopTableViewController, context: Context) {
        uiViewController.busStops = busStops
        uiViewController.isDraggingDestination = isDraggingDestination
        uiViewController.tableView.reloadData()
    }
}
