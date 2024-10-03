//
//  TaskListViewController.swift
//  lab-task-squirrel
//
//  Created by Charlie Hieger on 11/15/22.
//
import PhotosUI
import UIKit

class TaskListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateLabel: UILabel!

    var tasks = [Task]() {
        didSet {
            emptyStateLabel.isHidden = !tasks.isEmpty
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // UI candy: Hide 1st / top cell separator
        tableView.tableHeaderView = UIView()

        tableView.dataSource = self

        // Populate mocked data
        // Comment out this line if you want the app to load without any existing tasks.
        tasks = Task.mockedTasks
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // This will reload data in order to reflect any changes made to a task after returning from the detail screen.
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // Segue to Compose View Controller
        if segue.identifier == "ComposeSegue" {

            // Since the segue is connected to the navigation controller that manages the ComposeViewController
            // we need to access the navigation controller first...
            if let composeNavController = segue.destination as? UINavigationController,
                // ...then get the actual ComposeViewController via the navController's `topViewController` property.
               let composeViewController = composeNavController.topViewController as? TaskComposeViewController {

                // Update the tasks array for any new task passed back via the `onComposeTask` closure.
                composeViewController.onComposeTask = { [weak self] task in
                    self?.tasks.append(task)
                }
            }

            // Segue to Detail View Controller
        } else if segue.identifier == "DetailSegue" {
            if let detailViewController = segue.destination as? TaskDetailViewController,
                // Get the index path for the current selected table view row.
               let selectedIndexPath = tableView.indexPathForSelectedRow {

                // Get the task associated with the slected index path
                let task = tasks[selectedIndexPath.row]

                // Set the selected task on the detail view controller.
                detailViewController.task = task
            }
        }
    }
}

extension TaskListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskCell else {
            fatalError("Unable to dequeue Task Cell")
        }

        cell.configure(with: tasks[indexPath.row])

        return cell
    }
}

if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
    // Request photo library access
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
        switch status {
        case .authorized:
            // The user authorized access to their photo library
            // show picker (on main thread)
            DispatchQueue.main.async {
                self?.presentImagePicker()
                // Create a configuration object
                var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())

                // Set the filter to only show images as options (i.e. no videos, etc.).
                config.filter = .images

                // Request the original file format. Fastest method as it avoids transcoding.
                config.preferredAssetRepresentationMode = .current

                // Only allow 1 image to be selected at a time.
                config.selectionLimit = 1

                // Instantiate a picker, passing in the configuration.
                let picker = PHPickerViewController(configuration: config)

                // Set the picker delegate so we can receive whatever image the user picks.
                picker.delegate = self

                // Present the picker.
                present(picker, animated: true)
            }
        default:
            // show settings alert (on main thread)
            DispatchQueue.main.async {
                // Helper method to show settings alert
                self?.presentGoToSettingsAlert()
            }
        }
    }
} else {
    // Show photo picker
    presentImagePicker()
}
