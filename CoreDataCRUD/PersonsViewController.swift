//
//  ViewController.swift
//  CoreDataCRUD
//
//  Created by Hank.Lee on 10/07/2019.
//  Copyright © 2019 hyeongkyu. All rights reserved.
//

import UIKit
import CoreData

class PersonsViewController: UITableViewController {
    lazy var people: [Person] = {
        let request = NSFetchRequest<Person>(entityName: "Person")
        let people = try? persistentContainer.viewContext.fetch(request)
        return people ?? []
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Persons"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(showMenu))
        
        NotificationCenter.default.addObserver(self, selector: #selector(didManagedObjectChange(notification:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
    }
    
    @objc private func didManagedObjectChange(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let objects = userInfo[NSUpdatedObjectsKey] as? Set<Person>
                ?? userInfo[NSInsertedObjectsKey] as? Set<Person>
                ?? userInfo[NSDeletedObjectsKey] as? Set<Person>
            else {
                return
        }
        if objects.isEmpty { return }
        
        tableView.reloadData()
    }
    
    lazy var menus: [Menu] = [
        Menu(title: "New Person", handler: { [weak self] in
            self?.showPersonForm()
        }),
        Menu(title: "Teams", handler: { [weak self] in
            let viewController = TeamsViewController() 
            self?.navigationController?.pushViewController(viewController, animated: true)
        }),
    ]
    
    @objc private func showMenu() {
        let alert = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        menus.forEach { (menu) in
            alert.addAction(UIAlertAction(title: menu.title, style: .default, handler: { (action) in
                menu.handler?()
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showPersonForm(person: Person? = nil) {
        let alert = UIAlertController(title: "New Person", message: nil, preferredStyle: .alert)
        weak var textField: UITextField?
        
        alert.addTextField { (_textField) in
            textField = _textField
            textField?.text = person?.value(forKey: "name") as? String
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (action) in
            let name = textField?.text ?? ""
            if name.isEmpty { return }
            if let person = person {
                person.name = name
                try? persistentContainer.viewContext.save()
            } else {
                self?.createNewPerson(name: name)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func createNewPerson(name: String) {
        let managedContext = persistentContainer.viewContext
        let person = Person(context: managedContext)
        person.name = name
        do {
            try managedContext.save()
            people.append(person)
        } catch {
            print("save error = \(error)")
        }
    }
    
    private func personMenus(person: Person) -> [Menu] {
        return [
            Menu(title: "Rename", handler: { [weak self] in
                self?.showPersonForm(person: person)
            }),
            Menu(title: "Set Team", handler: { [weak self] in
                let viewController = TeamsViewController()
                viewController.person = person
                self?.navigationController?.pushViewController(viewController, animated: true)
            }),
            Menu(title: "Delete", handler: { [weak self] in
                do {
                    try person.validateForDelete()
                    self?.people.removeAll { $0 == person }
                    persistentContainer.viewContext.delete(person)
                    try persistentContainer.viewContext.save()
                } catch {
                    // do nothing
                }
            })
        ]
    }
    
    private func showPersonMenu(person: Person) {
        let alertController = UIAlertController(title: person.name, message: nil, preferredStyle: .actionSheet)
        let menus = personMenus(person: person)
        menus.forEach { (menu) in
            alertController.addAction(UIAlertAction(title: menu.title, style: .default, handler: { (action) in
                menu.handler?()
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let person = people[indexPath.row]
        cell.textLabel?.text = person.name
        cell.detailTextLabel?.text = person.team?.name
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showPersonMenu(person: people[indexPath.row])
    }
}

struct Menu {
    var title: String
    var handler: (() -> Void)?
}
