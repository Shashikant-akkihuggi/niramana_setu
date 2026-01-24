import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/task_service.dart';
import '../common/project_context.dart';

class OwnerTasksScreen extends StatelessWidget {
  const OwnerTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Overview')),
        body: const Center(child: Text('No active project')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Overview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: TaskService.getOwnerTasks(projectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final tasks = snapshot.data ?? [];
            
            if (tasks.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _TaskCard(task: tasks[i]),
            );
          },
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF16A34A);
      case 'Blocked':
        return const Color(0xFFDC2626);
      case 'In Progress':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFDC2626);
      case 'Low':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(task.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _statusColor(task.status).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        color: _statusColor(task.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 14,
                    color: _priorityColor(task.priority),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 12,
                      color: _priorityColor(task.priority),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${task.dueDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              if (task.managerRemark != null && task.managerRemark!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manager Remark:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.managerRemark!,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
