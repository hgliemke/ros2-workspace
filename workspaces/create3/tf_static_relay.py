#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, DurabilityPolicy
from tf2_msgs.msg import TFMessage

class TFStaticRelay(Node):
    def __init__(self):
        super().__init__('tf_static_relay')
        
        # QoS for tf_static (transient local)
        qos = QoSProfile(depth=10, durability=DurabilityPolicy.TRANSIENT_LOCAL)
        
        self.subscription = self.create_subscription(
            TFMessage, '/putin/tf_static', self.callback, qos)
        self.publisher = self.create_publisher(TFMessage, '/tf_static', qos)
        self.get_logger().info('TF static relay: /putin/tf_static -> /tf_static')

    def callback(self, msg):
        self.publisher.publish(msg)

def main(args=None):
    rclpy.init(args=args)
    node = TFStaticRelay()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
