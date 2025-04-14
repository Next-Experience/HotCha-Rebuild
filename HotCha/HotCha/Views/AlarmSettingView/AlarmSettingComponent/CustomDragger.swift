//
//  CustomDragger.swift
//  HotCha
//
//  Created by Yeji Seo on 4/11/25.
//


import SwiftUI
import UIKit

class DraggableBusStopTableViewController: UITableViewController {
    var busStops: [BusStop] = []
    var onArrivalStationChanged: ((Int) -> Void)? // 선택된 도착 정류장이 변경될 때 호출될 콜백
    
    private var backgroundView: UIView?
    private var sourceIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = UIColor(Color.gray900)
        tableView.separatorStyle = .none
        
        // 드래그 제스처 설정
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        tableView.addGestureRecognizer(longPress)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return busStops.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // 호스팅 컨트롤러를 사용하여 SwiftUI 뷰를 UIKit 셀에 삽입
        let busStop = busStops[indexPath.row]
        let stopCase = busStop.busStopCase
        
        // 셀 배경색 설정
        if busStop.arrivalStation {
            cell.backgroundColor = UIColor(Color.purpleOpacity10)
        } else {
            cell.backgroundColor = UIColor.clear
        }
        
        // 셀 설정 초기화
        cell.selectionStyle = .none
        
        // 기존 콘텐츠 뷰 제거
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // SwiftUI 뷰를 UIKit 뷰로 변환
        let hostingController = UIHostingController(
            rootView: BusStopElement(stopCase: stopCase, busStop: busStop)
        )
        
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        cell.contentView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
        ])
        
        // 셀 높이 고정
        hostingController.view.heightAnchor.constraint(equalToConstant: 78).isActive = true
        
        // 호스팅 컨트롤러를 셀과 연결
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        
        return cell
    }
    
    // 셀 높이 설정
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }
    
    // 셀 선택 처리
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        updateArrivalStation(at: indexPath.row)
    }
    
    // 도착 정류장 업데이트
    func updateArrivalStation(at index: Int) {
        // 모든 정류장의 도착 상태 초기화
        for i in 0..<busStops.count {
            busStops[i].arrivalStation = false
        }
        
        // 선택된 정류장만 도착 정류장으로 설정
        busStops[index].arrivalStation = true
        
        // 테이블 뷰 갱신
        tableView.reloadData()
        
        // 콜백 호출
        onArrivalStationChanged?(index)
    }
    
    // 롱 프레스 제스처 처리
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: tableView)
        
        switch gestureRecognizer.state {
        case .began:
            if let indexPath = tableView.indexPathForRow(at: location) {
                sourceIndexPath = indexPath
                
                // 선택된 셀을 가져옴
                guard let cell = tableView.cellForRow(at: indexPath) else { return }
                
                // 배경색 스냅샷 생성
                let highlightView = UIView(frame: cell.frame)
                highlightView.backgroundColor = UIColor(Color.purpleOpacity10)
                
                // 배경 뷰 테이블뷰에 추가
                tableView.insertSubview(highlightView, belowSubview: cell)
                backgroundView = highlightView
                
                // 도착 정류장 설정
                updateArrivalStation(at: indexPath.row)
            }
            
        case .changed:
            guard let backgroundView = backgroundView else { return }
            
            // 배경 뷰를 터치 위치에 맞게 이동
            var frame = backgroundView.frame
            frame.origin.y = location.y - frame.size.height / 2
            
            // 화면 범위 내에 유지
            let minY = tableView.rectForRow(at: IndexPath(row: 0, section: 0)).minY
            let maxY = tableView.rectForRow(at: IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)).maxY - frame.size.height
            
            frame.origin.y = max(minY, min(maxY, frame.origin.y))
            backgroundView.frame = frame
            
            // 현재 위치에 해당하는 인덱스 패스 찾기
            if let newIndexPath = tableView.indexPathForRow(at: location), newIndexPath != sourceIndexPath {
                // 선택 상태만 변경 (데이터 위치는 변경하지 않음)
                updateArrivalStation(at: newIndexPath.row)
                
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

/// SwiftUI를 위한 UIViewControllerRepresentable
struct DraggableBusStopList: UIViewControllerRepresentable {
    var busStops: [BusStop]
    var onArrivalStationChanged: (Int) -> Void
    
    func makeUIViewController(context: Context) -> DraggableBusStopTableViewController {
        let controller = DraggableBusStopTableViewController(style: .plain)
        controller.busStops = busStops
        controller.onArrivalStationChanged = onArrivalStationChanged
        return controller
    }
    
    func updateUIViewController(_ uiViewController: DraggableBusStopTableViewController, context: Context) {
        uiViewController.busStops = busStops
        uiViewController.tableView.reloadData()
    }
}

// 수정된 BusStopListView
struct DraggableBusStopListView: View {
    let bus: Bus_info_seoul
    let cityCode: Int
    @EnvironmentObject var busStopSeoulViewModel: BusStopSeoulViewModel
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                Color.gray900.ignoresSafeArea()
                
                DraggableBusStopList(
                    busStops: busStopSeoulViewModel.busStations,
                    onArrivalStationChanged: { index in
                        busStopSeoulViewModel.selectDestinationStataion(destIndex: index)
                    }
                )
                .padding(.top, 80)
                .padding(.bottom, 265)
            }
            .onAppear() {
                busStopSeoulViewModel.fetchBusStations(routeid: bus.busRouteId)
            }
            // TODO: 현재 필터링된 정류장 ID가 변경될 때마다 스크롤 위치 업데이트를 위한 로직 추가 필요
        }
    }
}
